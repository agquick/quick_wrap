class UIView

  def weak_ref
    WeakRef.new(self)
  end

  def qw_subview(superview, do_add=true, &block)
    self.qw_superview = superview
    #self.qw_resize :width, :height
    self.tap &block if block
    superview.addSubview(self) if do_add
    return self
  end

  def qw_superview=(superview)
    @qw_superview = WeakRef.new(superview)
  end

  def qw_superview
    return self.superview || @qw_superview
  end

  def x_offset
    return self.frame.origin.x + self.frame.size.width
  end
  def y_offset
    return self.frame.origin.y + self.frame.size.height
  end

  def qw_opts
    @qw_opts ||= {}
  end

  def qw_width_for_margin(val)
    return self.superview.size.width - self.origin.x - val
  end

  def qw_font(f, s=nil)
    if f.is_a? Symbol
      f, ts = AppDelegate::FONT_STYLES[f]
      s ||= ts
    end
    self.font = UIFont.fontWithName(f, size: s)
  end

  def qw_rounded(val, corners=:all)
    self.clipsToBounds = true

    if corners == :all
      self.layer.cornerRadius = val
    else
      enums = {top_left: UIRectCornerTopLeft, top_right: UIRectCornerTopRight, bottom_left: UIRectCornerBottomLeft, bottom_right: UIRectCornerBottomRight}
      enums_or = corners.map{|c| enums[c]}.reduce{|memo, obj| memo | obj}

      mask_path = UIBezierPath.bezierPathWithRoundedRect(self.bounds, byRoundingCorners: enums_or, cornerRadii: CGSizeMake(val, val))
      mask_layer = CAShapeLayer.layer
      mask_layer.frame = self.bounds
      mask_layer.path = mask_path.CGPath

      self.layer.mask = mask_layer
    end
  end

  def qw_multiline
    self.lineBreakMode = UILineBreakModeWordWrap
    self.numberOfLines = 0
  end

  def qw_border(c, w = 1.0)
    if c.nil?
      self.layer.borderColor = nil
      self.layer.borderWidth = 0.0
    else
      self.layer.borderColor = c.CGColor
      self.layer.borderWidth = w
    end
  end

  def qw_shadow(opts = {})
    self.layer.setShadowPath( UIBezierPath.bezierPathWithRect(self.bounds).CGPath ) unless opts[:optimized] == false

    self.layer.shadowOffset = CGSizeMake(0, 3)
    self.layer.shadowRadius = 5.0
    self.layer.shadowColor = UIColor.blackColor.CGColor
    self.layer.shadowOpacity = 1.0
    self.layer.masksToBounds = false

    self.layer.shouldRasterize = true unless opts[:optimized] == false
    self.layer.rasterizationScale = UIScreen.mainScreen.scale unless opts[:optimized] == false
    
  end

  def qw_decor(opt)
    case opt
    when :shadow
      UIImageView.new.qw_subview(self.superview) {|v|
        v.qw_frame_rel :bottom_of, self, 0, 0, 0, 15
        v.image = UIImage.imageNamed('quick_wrap/shadow-top')
      }
    end
  end

  def qw_gradient(colors)
    gradient = CAGradientLayer.layer
    gradient.frame = self.bounds
    gradient.colors = colors.collect{|c| c.CGColor}
    self.layer.insertSublayer(gradient, atIndex: 0)
  end

  def qw_resize(*vals)
    opts = {
      width: UIViewAutoresizingFlexibleWidth,
      height: UIViewAutoresizingFlexibleHeight,
      top: UIViewAutoresizingFlexibleTopMargin,
      left: UIViewAutoresizingFlexibleLeftMargin,
      bottom: UIViewAutoresizingFlexibleBottomMargin,
      right: UIViewAutoresizingFlexibleRightMargin
    }
    self.autoresizingMask = vals.map{|val| opts[val]}.reduce{|memo, obj| memo | obj}
  end

  def qw_bring_to_front
    self.superview.bringSubviewToFront(self)
  end

  def qw_send_to_back
    self.superview.sendSubviewToBack(self)
  end

  def qw_stretched_background(path)
    UIGraphicsBeginImageContext(self.frame.size)
    UIImage.imageNamed(path).drawInRect(self.bounds)
    image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    self.backgroundColor = UIColor.colorWithPatternImage(image)
  end

  def qw_background(path)
    self.setBackgroundColor(UIColor.alloc.initWithPatternImage(UIImage.imageNamed(path)))
  end

  def qw_bg_image(img, insets=nil, scale=UIViewContentModeScaleToFill)
    self.backgroundColor = UIColor.clearColor
    img_view = UIImageView.new.qw_subview(self) {|v|
      v.qw_frame 0, 0, 0, 0
      v.qw_resize :width, :height
      # build image
      img = UIImage.from_sym(img) unless img.is_a?(UIImage)
      img = img.resizableImageWithCapInsets(insets) if insets
      v.image = img
      v.contentMode = scale
    }
    self.sendSubviewToBack(img_view)
  end

  def qw_maintain_aspect
    self.contentMode = UIViewContentModeScaleAspectFit
  end

  def qw_content_fill
    self.contentMode = UIViewContentModeScaleAspectFill
    self.clipsToBounds = true
  end
  def qw_content_fit
    self.contentMode = UIViewContentModeScaleAspectFit
    self.clipsToBounds = true
  end
  def qw_content_top
    self.contentMode = UIViewContentModeTop
    self.clipsToBounds = true
  end

  def qw_bgcolor(r, g, b, a=1)
    self.backgroundColor = BW.rgba_color(r, g, b, a)
  end

  def qw_bg(color_name)
    self.backgroundColor = AppDelegate::COLORS[color_name]
  end

  def qw_text_align(align)
    case align
    when :left
      self.textAlignment = UITextAlignmentLeft
    when :right
      self.textAlignment = UITextAlignmentRight
    when :center
      self.textAlignment = UITextAlignmentCenter
    end
  end

  #def qw_frame(x, y, w, h)
    #self.frame = CGRectMake(x, y, w, h)
  #end

  def qw_frame(x, y, right, bottom, parent=nil)
    parent ||= self.qw_superview
    w = right > 0 ? right : parent.bounds.size.width - x - right.abs
    h = bottom > 0 ? bottom : parent.bounds.size.height - y - bottom.abs
    w = 0 if w < 0
    h = 0 if h < 0
    self.frame = CGRectMake(x.to_i, y.to_i, w.to_i, h.to_i)
  end

  def qw_margin_frame(x, y, right, bottom, parent=nil)
    self.qw_frame(x, y, right, bottom, parent)
  end

  def qw_frame_rel(pos, rel, rx, ry, w, h)
    case pos

    when :bottom_of
      x = rel.frame.origin.x + rx
      y = rel.y_offset + ry
    when :right_of
      x = rel.x_offset + rx
      y = rel.frame.origin.y + ry
    end

    self.qw_frame(x, y, w, h)
  end

  def qw_frame_from(pos, rx, ry, w, h)
    parent = self.qw_superview
    if pos == :bottom_right
      y = self.qw_superview.bounds.size.height - ry - h
      x = self.qw_superview.bounds.size.width - rx - w
    elsif pos == :bottom_left
      y = self.qw_superview.bounds.size.height - ry - h
      x = rx
    elsif pos == :top_right
      y = ry
      x = self.qw_superview.bounds.size.width - rx - w
    end
    self.qw_frame(x, y, w, h)
  end

  def qw_frame_set(*args)
    start = args[0]
    opts = {}
    case start
    when :normal, :reg
      opts[:type] = args[0]
      opts[:x] = args[1]
      opts[:y] = args[2]
      opts[:w] = args[3]
      opts[:h] = args[4]
    when :relative, :rel
      opts[:type] = :rel
      opts[:origin] = args[1]
      opts[:anchor] = args[2]
      opts[:x] = args[3]
      opts[:y] = args[4]
      opts[:w] = args[5]
      opts[:h] = args[6]
    when :right_of, :bottom_of
      opts[:type] = :rel
      opts[:origin] = args[0]
      opts[:anchor] = args[1]
      opts[:x] = args[2]
      opts[:y] = args[3]
      opts[:w] = args[4]
      opts[:h] = args[5]
    when :from
      opts[:type] = :from
      opts[:origin] = args[1]
      opts[:x] = args[2]
      opts[:y] = args[3]
      opts[:w] = args[4]
      opts[:h] = args[5]
    when :bottom_left, :bottom_right, :top_right
      opts[:type] = :from
      opts[:origin] = args[0]
      opts[:x] = args[1]
      opts[:y] = args[2]
      opts[:w] = args[3]
      opts[:h] = args[4]
    else
      opts[:type] = :reg
      opts[:x] = args[0]
      opts[:y] = args[1]
      opts[:w] = args[2]
      opts[:h] = args[3]
    end

    @qw_frame_opts = opts
    self.qw_reframe
  end

  def qw_reframe
    fo = @qw_frame_opts
    if !fo.nil?
      case fo[:type]
      when :relative, :rel
        self.qw_frame_rel fo[:origin], fo[:anchor], fo[:x], fo[:y], fo[:w], fo[:h]
      when :from
        self.qw_frame_from fo[:origin], fo[:x], fo[:y], fo[:w], fo[:h]
      else
        self.qw_frame fo[:x], fo[:y], fo[:w], fo[:h]
      end
    end
  end

  def qw_frame_opts
    @qw_frame_opts
  end

  def qw_layout_subviews
    self.subviews.each do |view|
      view.qw_reframe unless view.qw_frame_opts.nil?
    end
  end

  def qw_center
    f = self.frame
    f.origin.x = ((self.qw_superview.size.width / 2.0) - (f.size.width / 2.0)).to_i
    f.origin.y = ((self.qw_superview.size.height / 2.0) - (f.size.height / 2.0)).to_i
    self.frame = f
  end

  def qw_center_x(y=nil)
    f = self.frame
    f.origin.x = ((self.qw_superview.size.width / 2.0) - (f.size.width / 2.0)).to_i
    f.origin.y = y if y
    self.frame = f
  end

  def qw_origin(x, y)
    f = self.frame
    f.origin.x = x
    f.origin.y = y
    self.frame = f
  end

  def qw_size(w, h, anim=true)
    f = self.frame
    f.size.width = w unless w.nil?
    f.size.height = h unless h.nil?
    if anim
      self.qw_animate do |v|
        v.frame = f
      end
    else
      self.frame = f
    end
  end

  def qw_rotate(deg)
    rotationTransform = CGAffineTransformIdentity
    rotationTransform = CGAffineTransformRotate(rotationTransform, (deg / 180.0 * 3.14159))
    UIView.beginAnimations("swing", context:nil)
    UIView.setAnimationDuration(0.25)
    
    self.transform = rotationTransform

    UIView.commitAnimations
  end

  def qw_blur(radius=3.0)
    filter = CAFilter.filterWithName("gaussianBlur")
    filter.setValue(radius, forKey: "inputRadius")
    filter.setValue(true, forKey: "inputHardEdges")
    self.layer.filters = [filter]
  end

  def qw_remove_blur
    self.layer.filters = nil
  end

  def qw_colors(fg, bg=UIColor.clearColor)
    if fg.is_a? Symbol
      self.textColor = AppDelegate::COLORS[fg]
    else
      self.textColor = fg
    end
    if bg.is_a? Symbol
      self.backgroundColor = AppDelegate::COLORS[bg]
    else
      self.backgroundColor = bg
    end
  end

  def qw_style(style)
    v = self
    del_style = AppDelegate::VIEW_STYLES[style]
    if del_style
      del_style.yield(self)
      return
    end

    case style
    when :gtv
      v.qw_font 'Avenir-Book', 14
      v.qw_rounded 15
      #v.qw_border BW.rgb_color(29, 29, 29), 1.0
    when :textfield
      v.qw_font 'Avenir-Book', 14
      v.backgroundColor = UIColor.whiteColor
      v.textColor = UIColor.blackColor
      v.clearButtonMode = UITextFieldViewModeWhileEditing if v.is_a?(UITextField)
      v.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter if v.is_a?(UITextField)
      v.returnKeyType = UIReturnKeyDone
      v.qw_rounded 5
      v.qw_border BW.rgb_color(220, 221, 222), 1.0
    when :label
      v.backgroundColor = UIColor.clearColor
      v.textColor = UIColor.whiteColor
      v.qw_font 'Avenir-Book', 14
    when :label2
      v.backgroundColor = UIColor.clearColor
      v.textColor = BW.rgb_color(25, 25, 25)
      v.qw_font 'Avenir-Book', 14
    when :button_green
      v.qw_font 'Avenir-Book', 16
      v.backgroundColor = BW.rgb_color(125, 170, 71)
      v.qw_rounded 3
      v.setTitleColor(UIColor.whiteColor, forState:UIControlStateNormal)
      v.setTitleColor(UIColor.grayColor, forState:UIControlStateHighlighted)
    when :button_red
      v.qw_font 'Avenir-Book', 16
      v.backgroundColor = BW.rgb_color(200, 68, 68)
      v.qw_rounded 3
      v.setTitleColor(UIColor.whiteColor, forState:UIControlStateNormal)
      v.setTitleColor(UIColor.grayColor, forState:UIControlStateHighlighted)
    when :button_gray
      v.qw_font 'Avenir-Book', 14
      v.backgroundColor = BW.rgb_color(236, 237, 238)
      v.qw_rounded 3
      v.setTitleColor(BW.rgb_color(118, 123, 133), forState:UIControlStateNormal)
      v.setTitleColor(UIColor.whiteColor, forState:UIControlStateHighlighted)
    when :button
      v.qw_font 'Avenir-Black', 14
      v.qw_gradient [BW.rgb_color(102, 102, 102), BW.rgb_color(51, 51, 51)]
      v.qw_rounded 5
      v.qw_border UIColor.blackColor, 1.0
      v.setTitleColor(UIColor.whiteColor, forState:UIControlStateNormal)
      v.setTitleColor(UIColor.orangeColor, forState:UIControlStateHighlighted)
    when :badge_small
      v.backgroundColor = BW.rgb_color(42, 52, 58)
      v.textColor = BW.rgb_color(150, 156, 167)
      v.textAlignment = UITextAlignmentCenter
      v.qw_font 'Avenir-Black', 10
      v.qw_rounded(7)
    end
  end

  def default_style(style)
    qw_style(style)
  end

  def qw_show_loading
    QuickWrap.show_loading(self)
  end

  def qw_hide_loading
    QuickWrap.hide_loading(self)
  end

  def qw_loading(val)
    val ? qw_show_loading : qw_hide_loading
  end

  def qw_fade_in
    self.alpha = 0.0
    self.hidden = false
    UIView.animateWithDuration(0.2,
      animations: lambda {
        self.alpha = 1.0
      },
      completion: nil)
  end

  def qw_fade_out
    UIView.animateWithDuration(0.2,
      animations: lambda {
        self.alpha = 0
      },
      completion: lambda {|finished|
        self.hidden = true
      })
  end

  def qw_animate(type=nil, &block)
    if type.nil?
      UIView.animateWithDuration(0.2,
        animations: lambda{
          block.call(self)
        },
        completion: nil)
    else
      case type
      when :fade_in
        self.alpha = 0
        self.hidden = false
        anim = lambda {
          self.alpha = 1.0
        }
        comp = lambda {|f|
          self.hidden = false
        }
      when :fade_out
        anim = lambda {
          self.alpha = 0
        }
        comp = lambda {|f|
          self.hidden = true
        }
      end
      UIView.animateWithDuration(0.2, animations: anim, completion: comp)
    end
  end

  def qw_handle_gesture(&block)
    self.when_tapped { block.call(:tapped) }
    self.when_pressed {|sender| block.call(:pressed) if sender.state == UIGestureRecognizerStateBegan}
  end

end
