module QuickWrap

  class Form < UIScrollView
    include QW::WeakDelegate

    attr_accessor :elements, :selected_element

    def initWithFrame(frame)
      super

      @elements = {}
      self.build_view

      self.subviews.each do |v|
        @elements[v.key] = v if v.is_a?(FormElement)
        v.tag = 1
      end

      return self
    end

    def build_view

    end

    def layoutSubviews
      super
      self.qw_layout_subviews
      self.update_size
    end

    def [](key)
      self.elements[key].value
    end
    def []=(key, val)
      self.elements[key].value = val
    end

    def update_size
      content_views = self.subviews.select{|v| v.tag == 1}
      heights = content_views.collect{|el| el.y_offset}
      widths = content_views.collect{|el| el.x_offset}
      self.contentSize = CGSizeMake(widths.max, heights.max)
    end

    def handle_element_gesture(key, gesture, element)
      self.set_element_focus(element)
    end

    def set_element_focus(element)
      self.elements.values.each do |el|
        el.handle_blur unless el == element
      end
      element.handle_focus
      self.selected_element = element
      self.setNeedsLayout
      App.run_after(0.5) { self.scroll_to_element(element) }
    end

    def set_element_blur(element)
      element.handle_blur
      self.selected_element = nil
      self.setNeedsLayout
    end

    def blur
      self.set_element_blur(self.selected_element) unless self.selected_element.nil?
    end

    def show_date_picker(date_val, mode=UIDatePickerModeDateAndTime)
      if @picker.nil?
        @picker = UIDatePicker.new.qw_subview(self) {|v|
          v.qw_frame_from :bottom_left, 0, 0, 0, 200
          v.addTarget(self, action: :handle_date_picker_changed, forControlEvents: UIControlEventValueChanged)
        }
      else
        @picker.hidden = false
      end

      @picker.datePickerMode = mode
      @picker.date = NSDate.dateWithTimeIntervalSince1970(date_val)
      @picker.timeZone = NSTimeZone.systemTimeZone
    end

    def hide_date_picker
      @picker.hidden = true if @picker
    end

    def handle_date_picker_changed
      self.selected_element.value = @picker.date.timeIntervalSince1970.to_i
    end

    def show_asset_picker(element, &block)
      QuickWrap::Camera.display_picker(from_rect: element.bounds, view: self, delegate: self.delegate || App.delegate.root_ctr) do |result|
        block.call(result)
      end
    end

    def select_next_element
      idx = self.elements.values.index(self.selected_element)
      el = self.elements.values[idx+1]
      if el
        self.set_element_focus(el)
      end
    end

    def scroll_to_element(element=nil)
      element ||= @selected_element
      return if element.nil?
      self.scrollRectToVisible(element.frame, animated: true)
    end

    def observe_app_events
    end

    def unobserve_app_events
      App.delegate.off(:all, self)
    end

  end

  class FormElement < UIView

    attr_accessor :options, :key

    def initWithFrame(frame)
      super

      @value = nil
      @enabled = true
      @change_fn = nil
      @process_fn = lambda {|val| val}
      @is_handling_change = false
      @has_focus = false

      self.qw_resize :width

      @panel_bg = UIView.new.qw_subview(self) {|v|
        v.qw_resize :width
      }

      @img_icon = UIImageView.new.qw_subview(self) {|v|

      }

      @lbl_title = UILabel.new.qw_subview(self) {|v|
        v.qw_resize :width
      }

      @lbl_help = UILabel.new.qw_subview(self) {|v|
        v.qw_resize :width
        v.hidden = true
      }

      @ln_bottom = UIView.new.qw_subview(self) {|v|
        v.qw_resize :top
      }

      self.when_tapped {self.form.handle_element_gesture(self.key, :tapped, self)}

      return self
    end

    def layoutSubviews
      self.qw_layout_subviews
    end

    def focus
      self.form.set_element_focus(self)
    end

    def blur
      self.form.set_element_blur(self)
    end

    def handle_focus
    end

    def handle_blur
    end

    def has_focus?
      self.form.selected_element == self
    end

    def enabled?
      @enabled == true
    end

    def enabled=(val)
      @enabled = val
      self.blur if val == false && self.has_focus?
      self.setNeedsLayout
    end

    def form
      self.superview
    end

    def send_gesture(gest)
      self.form.handle_element_gesture(key, gest, self)
    end

    def title_label
      @lbl_title
    end

    def help_label
      @lbl_help
    end

    def line
      @ln_bottom
    end

    def help_text=(val)
      @lbl_help.hidden = false
      @lbl_help.text = val
    end

    def bg_panel
      @panel_bg
    end

    def value
      @value
    end

    def value=(val)
      @value = @process_fn.call(val)
      self.handle_value_changed
    end

    def on_change(&block)
      @change_fn = block
    end

    def process_value(&block)
      @process_fn = block
    end

    def handle_value_changed
      return if @is_handling_change == true
      @is_handling_change = true
      @change_fn.call(@value) if @change_fn
      @is_handling_change = false
    end

    def title=(val)
      @lbl_title.text = val
    end

    def default_style
      :form_element
    end

  end

  class FormLabel < FormElement

    def default_style
      :form_element_label
    end

  end

  class FormTextField < FormElement

    def initWithFrame(frame)
      super
      @txt_view = UITextField.new.qw_subview(self) {|v|
        v.qw_resize :width
        v.delegate = self
        v.clearButtonMode = UITextFieldViewModeWhileEditing
        v.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter
        v.returnKeyType = UIReturnKeyDone
      }
      return self
    end

    def type=(val)
      case val
      when :email
        self.text_view.keyboardType = UIKeyboardTypeEmailAddress
      when :number
        self.text_view.keyboardType = UIKeyboardTypeNumberPad
      when :phone
        self.text_view.keyboardType = UIKeyboardTypePhonePad
      when :password
        self.text_view.secureTextEntry = true
      end
    end

    def text_view
      @txt_view
    end

    def handle_blur
      @txt_view.resignFirstResponder
    end

    def handle_focus
      @txt_view.becomeFirstResponder
    end

    def textFieldDidBeginEditing(tv)
      self.send_gesture(:entered)
    end

    def textFieldShouldReturn(tv)
      if tv.returnKeyType == UIReturnKeyNext
        self.form.select_next_element
      else
        tv.resignFirstResponder
      end
    end

    def value
      @value = @txt_view.text
    end

    def value=(val)
      super
      @txt_view.text = val
    end

  end

  class FormTextView < FormElement

    def initWithFrame(frame)
      super
      @txt_view = UITextView.new.qw_subview(self) {|v|
        v.qw_resize :width
        v.delegate = self
      }
      return self
    end

    def text_view
      @txt_view
    end

    def handle_blur
      @txt_view.resignFirstResponder
    end

    def handle_focus
      @txt_view.becomeFirstResponder
    end

    def textViewDidBeginEditing(tv)
      self.send_gesture(:entered)
    end

    def value
      @value = @txt_view.text
    end

    def value=(val)
      super
      @txt_view.text = val
    end

  end

  class FormButton < FormElement
    def initWithFrame(frame)
      super
      self.subviews.each {|v| v.hidden = true}
      @btn = QuickWrap::FlexButton.new.qw_subview(self) {|v|
        v.qw_frame 0, 0, 0, 0
        v.qw_resize :width, :height
      }
      return self
    end

    def action(&block)
      @btn.when(UIControlEventTouchUpInside) {
        block.call
      }
    end

    def default_style
      :button_gray
    end
  end

  class FormDateTimePicker < FormElement

    def initWithFrame(frame)
      super
      @mode = UIDatePickerModeDateAndTime
      @lbl_view = UILabel.new.qw_subview(self)
      return self
    end

    def label_view
      @lbl_view
    end

    def handle_focus
      picker = self.form.show_date_picker(self.value, @mode)
    end

    def handle_blur
      self.form.hide_date_picker
    end

    def mode=(val)
      @mode = val
    end

    def value=(val)
      super
      case @mode
      when UIDatePickerModeDateAndTime, nil
        @lbl_view.text = Time.at(@value).localtime.strftime("%B %-d, %Y  %l:%M %p")
      when UIDatePickerModeDate
        @lbl_view.text = Time.at(@value).localtime.strftime("%B %-d, %Y")
      when UIDatePickerModeTime
        @lbl_view.text = Time.at(@value).localtime.strftime("%l:%M %p")
      end
    end

    def default_style
      :form_element_date
    end
  end

  class FormSwitch < FormElement

    def initWithFrame(frame)
      super

      @switch_view = UISwitch.new.qw_subview(self) {|v|
        v.when(UIControlEventValueChanged) {
          self.value = @switch_view.isOn
        }
      }

      return self
    end

    def switch_view
      @switch_view
    end

    def value=(val)
      super
      @switch_view.on = @value
    end

  end

  class FormImage < FormElement

    def initWithFrame(frame)
      super

      @source_mode = :any
      @image_selected_fn = nil

      @img_view = UIImageView.new.qw_subview(self) {|v|
        v.qw_content_fill
        v.when_tapped {
          self.prompt_select_picture
        }
      }
      return self
    end

    def image_view
      @img_view
    end

    def source_mode=(val)
      @source_mode=val
    end

    def value=(val)
      super
      if @value.is_a? UIImage
        @img_view.image = @value
      else
        @img_view.source_url = @value
        @img_view.load_from_url
      end
    end

    def has_new_image?
      @value.is_a? UIImage
    end

    def prompt_select_picture
      if @source_mode == :any
        p = QuickWrap::ActionSheet.new
        p.add_button :library, "Choose from library...", lambda {
          self.show_asset_picker
        }
        p.add_button :cancel, "Cancel"
        p.showInView(App.window)
      elsif @source_mode == :library
        self.show_asset_picker
      end
    end

    def show_asset_picker
      self.form.show_asset_picker(self) do |result|
        img = result[:original_image]
        if img
          if @image_selected_fn
            @image_selected_fn.call(img)
          else
            self.value = img
          end
        end
      end
    end

    def on_image_selected(&block)
      @image_selected_fn = block
    end

    def default_style
      :form_element_image
    end

  end

end
