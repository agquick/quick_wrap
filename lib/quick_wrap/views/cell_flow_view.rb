module QuickWrap

  class CellFlowView < UIView
    include QuickWrap::Eventable
    include QuickWrap::WeakDelegate

    attr_accessor :options, :rows, :selected_scope

    def initWithFrame(frame)
      super

      vw = frame.size.width
      vh = frame.size.height

      self.qw_resize :height, :width
      self.backgroundColor = UIColor.clearColor

      @cell_registry = {}

      @lbl_placeholder = UILabel.new.qw_subview(self) {|v|
        v.qw_frame_set 0, 80, 0, 20
        v.qw_resize :width
        v.qw_font :reg_18
        v.qw_colors UIColor.grayColor
        v.qw_text_align :center
        v.hidden = true
      }

      @col_view = UICollectionView.alloc.initWithFrame(CGRectZero, collectionViewLayout: CVCustomLayout.new).qw_subview(self) {|v|
        v.qw_frame_set 0, 0, 0, 0
        v.qw_resize :height, :width
        v.backgroundColor = UIColor.clearColor
        v.delegate = self
        v.dataSource = self
        v.alwaysBounceVertical = true
        v.collectionViewLayout.spacing = 0
        v.collectionViewLayout.insets = UIEdgeInsetsMake(0, 0, 0, 0)
      }


      @pnl_selected_scope = UIView.new.qw_subview(self) {|v|
        v.qw_frame 0, 0, 0, 40
        v.qw_resize :width
        v.qw_bgcolor 52, 152, 219, 0.5
        v.hidden = true
      }
        @lbl_selected_scope = UILabel.new.qw_subview(@pnl_selected_scope) {|v|
          v.qw_frame 0, 0, 0, 40
          v.qw_resize :width
          v.qw_style :label 
          v.qw_font 'Avenir-Black', 16
          v.qw_text_align :center
        }
        @img_selected_scope_close = UIImageView.new.qw_subview(@pnl_selected_scope) {|v|
          v.qw_frame vw - 25, 10, 20, 20
          v.qw_resize :left, :bottom
          v.image = UIImage.imageNamed('quick_wrap/close-white')
          v.when_tapped { self.unselect_scope }
        }

      self.configure

      return self
    end

    def layoutSubviews

      @col_view.qw_reframe
    end

    def configure
      self.rows = []
      self.options = {}

    end

    def configure_layout
      yield @col_view.collectionViewLayout
    end

    def update_insets(opts)
      layout = @col_view.collectionViewLayout
      insets = layout.insets
      insets.top = opts[:top] if opts[:top]
      insets.bottom = opts[:bottom] if opts[:bottom]
      layout.insets = insets
      @col_view.reloadData
    end

    def register_cell(type, cell_class, opts={})
      opts[:cell_class] = cell_class
      @cell_registry[type] = opts
      @col_view.registerClass(cell_class, forCellWithReuseIdentifier: type.to_s)
    end

    def register_infinite_scroll_handler(block)
      @col_view.addInfiniteScrollingWithActionHandler lambda{
        if @col_view.contentSize.height < @col_view.size.height
          @col_view.infiniteScrollingView.stopAnimating
        else
          @col_view.infiniteScrollingView.startAnimating
          block.call
        end
      }
    end

    def register_pull_to_refresh_handler(block)
      @col_view.addPullToRefreshWithActionHandler block
      @col_view.pullToRefreshView.titles = ['Pull to update...', 'Release to update...', 'Updating...']
      @col_view.pullToRefreshView.titleLabel.qw_font 'Avenir-Book', 12
    end

    def observe_app_events
    end

    def unobserve_app_events
      App.delegate.off(:all, self)
    end

    ## ACCESSORS

    def reload_data
      self.build_rows
      self.position_rows
      EM.schedule_on_main { @col_view.reloadData }
      @lbl_placeholder.hidden = self.has_data?
    end

    def load_initial_data

    end

    def has_data?
      !self.rows.empty?
    end

    def show_loading
      @lbl_placeholder.hidden = true
      QuickWrap.show_loading(self)
    end

    def hide_loading
      QuickWrap.hide_loading(self)
      @col_view.infiniteScrollingView.stopAnimating unless @col_view.infiniteScrollingView.nil?
      @col_view.pullToRefreshView.stopAnimating unless @col_view.pullToRefreshView.nil?
    end

    def placeholder=(val)
      @lbl_placeholder.text = val
    end

    def select_scope(scope)
      self.selected_scope = scope
      @pnl_selected_scope.qw_fade_in
      @lbl_selected_scope.text = "Add to #{scope[:title]}"
      self.reload_data
    end

    def unselect_scope
      self.selected_scope = nil
      @pnl_selected_scope.qw_fade_out
      self.reload_data
    end

    def add_to_selected_scope(scope)
    end

    def col_view
      @col_view
    end

    def handle_row_data(data)
      self.rows.select{|r| r[:id] == data['id']}.each do |r|
        r[:model].handle_data(data)
      end
      self.reload_data
    end

    def delete_row(row_id)
      self.rows.delete_if{|r| r[:id] == row_id}
      self.reload_data
    end

    ## INTERACTIONS

    def numberOfSectionsInCollectionView(cv)
      return 1
    end

    def collectionView(cv, numberOfItemsInSection:section_idx)
      return self.rows.length
    end

    def collectionView(cv, cellForItemAtIndexPath: index_path)
      # determine identifier from rows
      scope = self.rows[index_path.row]
      ident = scope[:type]
      pc = cv.dequeueReusableCellWithReuseIdentifier(ident.to_s, forIndexPath: index_path)
      if pc.scope.nil?
        pc.qw_handle_gesture {|g| self.handle_cell_gesture(ident, g, pc)}
        pc.delegate = self if pc.respond_to?('delegate=')
      end
      pc.from_scope(scope)
      return pc
    end

    def collectionView(cv, layout: layout, scopeForItemAtIndexPath: index_path)
      scope = self.rows[index_path.row]
      #QuickWrap.log "#{frame.inspect} for #{scope.inspect}"
      return scope
    end

    def handle_cell_gesture(ident, gesture, cell)
      @delegate.handle_cell_gesture(ident, gesture, cell, self) if self.delegate.respond_to?(:handle_cell_gesture)
    end

    def handle_post_created(data)
    end
    def handle_collection_updated(data)
    end
    def handle_collection_deleted(data)
    end
    def handle_collection_posts_updated(data)
    end
    def handle_post_updated(data)
    end
    def handle_post_deleted(data)
    end

    ## HELPERS

    def build_rows
    end

    def position_rows
      insets = @col_view.collectionViewLayout.insets
      spacing = @col_view.collectionViewLayout.spacing
      il = insets.left
      ir = insets.right
      vw = @col_view.frame.size.width
      cy = insets.top
      self.rows.each do |row|
        t = cy + (row[:margin_top] || 0)
        l = il + (row[:margin_left] || 0)
        w = vw - ir - (row[:margin_right] || 0) - l
        row[:width] = w
        self.set_scope_layout(row)
        h = row[:height]
        row[:frame] = CGRectMake(l, t, w, h)
        cy = t + h + (row[:margin_bottom] || 0) + spacing
      end
    end

    def set_scope_layout(scope)
      opts = @cell_registry[scope[:type]]
      opts[:cell_class].set_layout(scope) if opts[:cell_class].respond_to?(:set_layout)
      scope[:height] = opts[:height] if opts[:height]
      scope[:height] ||= 80
      return scope
    end

    def scroll_to_bottom
      offset = @col_view.contentSize.height - @col_view.size.height
      offset = 0 if offset < 0
      @col_view.setContentOffset([0, offset], animated: true)
    end

    ## CVCUSTOMLAYOUT
    class CVCustomLayout < UICollectionViewLayout

      attr_accessor :insets, :spacing, :has_sticky

      def init
        super
        self.init_params
        return self
      end

      def init_params
        self.spacing ||= 0
        self.insets ||= UIEdgeInsetsMake(0, 0, 0, 0)
        self.has_sticky = false
        @attrs = []
        @max_height = 0
        @max_width = 0
      end

      def inset=(val)
        @insets=val
      end

      def inset
        @insets
      end

      def max_width
        @max_width
      end
      def max_height
        @max_height
      end

      def prepareLayout
        super 
        @max_height = 0
        @max_width = 0

        cv = self.collectionView
        return if cv.numberOfSections == 0
        item_count = cv.dataSource.collectionView(cv, numberOfItemsInSection: 0)
        @attrs = Array.new(item_count)
        return if item_count == 0

        sticky = nil
        y_offset = cv.contentOffset.y

        (0..(item_count-1)).each do |idx|
          index_path = NSIndexPath.indexPathForItem(idx, inSection: 0)
          attr = UICollectionViewLayoutAttributes.layoutAttributesForCellWithIndexPath(index_path)
          @attrs[idx] = attr
          row_scope = cv.delegate.collectionView(cv, layout: self, scopeForItemAtIndexPath: index_path)
          next if row_scope.nil?

          frame = row_scope[:frame]
          attr.frame = frame
          @max_width = [@max_width, frame.origin.x + frame.size.width].max
          @max_height = [@max_height, frame.origin.y + frame.size.height].max
          sticky = attr if (row_scope[:sticky] && frame.origin.y < (self.insets.top + y_offset))
          attr.zIndex = row_scope[:z_index] if row_scope[:z_index]
          attr.zIndex = 1024 + idx if row_scope[:sticky]
        end

        # Reposition sticky element. Last sticky element should be at the top
        sticky.frame = CGRectMake(self.insets.left, y_offset + self.insets.top, sticky.frame.size.width, sticky.frame.size.height) if sticky

      end

      def layoutAttributesForElementsInRect(rect)
        @attrs.select do |attr|
          CGRectIntersectsRect(rect, attr.frame)
        end
      end

      def layoutAttributesForItemAtIndexPath(index_path)
        @attrs[index_path.item]
      end

      def shouldInvalidateLayoutForBoundsChange(bounds)
        return self.has_sticky
      end

      def collectionViewContentSize
        if self.collectionView.numberOfSections == 0
          return CGSizeZero
        else
          size = self.collectionView.frame.size
          size.width = @max_width + self.insets.right
          size.height = @max_height + self.insets.bottom
          return size
        end
      end

    end
    ## END CVCUSTOMLAYOUT


  end

end
