class UIImage

  def self.load_from_url(url)
    if url.match(/^http[s]?:\/\/.*/)
      UIImage.alloc.initWithData(NSData.dataWithContentsOfURL(NSURL.URLWithString(url)))
    else
      UIImage.imageNamed(url)
    end
  end

  def self.addTransparentBorder(image)
    imageRrect = CGRectMake(0, 0, image.size.width, image.size.height)
    UIGraphicsBeginImageContext( imageRrect.size )
    image.drawInRect( CGRectMake(1,1,image.size.width-2,image.size.height-2) )
    image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image

  end

  def self.from_color(color)
    rect = CGRectMake(0, 0, 1, 1)
    # Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    color.setFill
    UIRectFill(rect)   # Fill it with your color
    image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
  end

  def self.from_sym(sym)
    if sym.is_a?(Symbol)
      UIImage.imageNamed(AppDelegate::IMAGES[sym])
    else
      UIImage.imageNamed(sym)
    end
  end

  def croppedToSize(targetSize)
    sourceImage = self
    return nil if sourceImage.nil?

    imageSize = sourceImage.size
    width = imageSize.width
    height = imageSize.height
    targetWidth = targetSize.width
    targetHeight = targetSize.height
    scaleFactor = 0.0
    scaledWidth = targetWidth
    scaledHeight = targetHeight
    thumbnailPoint = CGPointMake(0.0, 0.0)

    if CGSizeEqualToSize(imageSize, targetSize) == false
      widthFactor = targetWidth / width
      heightFactor = targetHeight / height

      scaleFactor = widthFactor > heightFactor ? widthFactor : heightFactor
      scaledWidth = width * scaleFactor
      scaledHeight = height * scaleFactor

      if widthFactor > heightFactor
        thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
      elsif widthFactor < heightFactor
        thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
      end
    end

    # now size image

    UIGraphicsBeginImageContext(targetSize)
    thumbnailRect = CGRectZero
    thumbnailRect.origin = thumbnailPoint
    thumbnailRect.size.width = scaledWidth
    thumbnailRect.size.height = scaledHeight
    sourceImage.drawInRect(thumbnailRect)
    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage

  end

  def scale_to_size(targetSize, mode=:cover)

    if mode == :cover
      wr = targetSize.width / self.size.width
      hr = targetSize.height / self.size.height
      if hr > wr
        dh = targetSize.height
        dw = self.size.width * targetSize.height / self.size.height
      else
        dw = targetSize.width
        dh = self.size.height * targetSize.width / self.size.width
      end
      newSize = CGSizeMake(dw, dh)
    else
      newSize = targetSize
    end

    newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height))

    begin
      UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
      self.drawInRect(newRect)
      newImage = UIGraphicsGetImageFromCurrentImageContext()
      raise "No image from context" if newImage.nil?
      UIGraphicsEndImageContext()
    rescue
      QW.log newSize.inspect
      return self
    end
    return newImage
  end

  def stretchedToSize(targetSize)
    UIGraphicsBeginImageContext(targetSize)
    self.drawInRect(CGRectMake(0, 0, targetSize.width, targetSize.height))
    image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image
  end

  def qw_crop(size, mode=:center)
    modes = {center: NYXCropModeCenter, top_center: NYXCropModeTopCenter}
    self.cropToSize(size, usingMode: modes[mode])
  end

  def qw_scale_and_crop(size, mode=:center)
    self.scaleToSize(size, usingMode: NYXResizeModeAspectFill).qw_crop(size, mode)
  end

  def qw_scale(size)
    #self.scaleToSize(size, usingMode: NYXResizeModeAspectFill)
    self.scale_to_size(size)
  end

end
