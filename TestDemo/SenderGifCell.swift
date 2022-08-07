//
//  SenderGifCell.swift
//  Zuddl
//
//  Created by Venkata Phanindhra on 28/07/22.
//

import UIKit
import GiphyUISDK
import ZuddlKit
import AVFoundation

class SenderGifCell: UITableViewCell {
  
  let bubbleWidth: CGFloat = 250
  
  let gifImageView : GPHMediaView = {
    let imageView = GPHMediaView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.layer.cornerRadius = Spacing.double.value
    imageView.layer.masksToBounds = false
    imageView.contentMode = .scaleAspectFit
    imageView.showAttribution = true
    return imageView
  }()
  
  let placeHolderGifImage: UIImageView = {
    let image = UIImageView()
    image.image = ImageAsset.gifPlaceHolder.image
    image.isUserInteractionEnabled = true
    return image
  }()
  
  let timeLabel: UILabel = {
    $0.textColor = Color.grayText.value
    $0.textAlignment = .left
    $0.numberOfLines = 1
    $0.font = Font.subheadline.value
    $0.translatesAutoresizingMaskIntoConstraints = false
    return $0
  }(UILabel())
  
  let bubbleView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = Spacing.double.value
    view.layer.masksToBounds = false
    view.backgroundColor = Color.secondaryBackground.value
    return view
  }()
  
  var mediaObj : GPHMedia?
  var isAlreadyLoaded: Bool = false
  
  // MARK: - Initializers
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    setupViews()
  }
  
  fileprivate func setupViews() {
    contentView.backgroundColor = Color.background.value
    
    contentView.addSubview(bubbleView)
    bubbleView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.custom(12).value)
      make.bottom.equalToSuperview().offset(-Spacing.custom(12).value)
      make.right.equalToSuperview().offset(-Spacing.double.value)
      make.width.equalTo(bubbleWidth)
    }
    
    bubbleView.addSubview(timeLabel)
    timeLabel.snp.makeConstraints { make in
      make.right.equalTo(bubbleView).offset(-12)
      make.bottom.equalTo(bubbleView)
      make.height.equalTo(30)
    }
    
    bubbleView.addSubview(gifImageView)
    gifImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(Spacing.half.value)
      make.right.equalToSuperview().offset(-Spacing.half.value)
      make.top.equalToSuperview().offset(Spacing.half.value)
      make.bottom.equalTo(timeLabel.snp.top)
    }
    
    gifImageView.addSubview(placeHolderGifImage)
    placeHolderGifImage.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }

    let tapAction = UITapGestureRecognizer(target: self,
                                           action: #selector(imageTapped(gestureRecognizer:)))
    gifImageView.addGestureRecognizer(tapAction)

  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    gifImageView.image = nil
  }
  
  func configureMediaData(_ id: String, message : PeopleChatMessage, dateformater : DateFormatter, eventId: String) {
    var timeIs = ""
    
    if let timeis = message.getNormalDateFormate() {
      timeIs = dateformater.string(from: timeis)
    }
    timeLabel.text = timeIs
    timeLabel.textColor = Color.text.value(forEventId: eventId)
    bubbleView.backgroundColor = Color.secondary.value(forEventId: eventId)
    placeHolderGifImage.isHidden = true
  
//    if !isAlreadyLoaded {
//      isAlreadyLoaded = true
      GiphyCore.shared.gifByID(id) { (response, _) in
        if let media = response?.data {
          
          guard let url = media.url(rendition: .fixedWidth, fileType: .gif) else { return }
          GPHCache.shared.downloadAssetData(url) { (data, error) in
            DispatchQueue.main.async { [weak self] in
              self?.mediaObj = media
              self?.gifImageView.image = UIImage(data: data!)
              self?.gifImageView.layer.cornerRadius = Spacing.double.value
              self?.gifImageView.layer.masksToBounds = true
              self?.playGifAnimation(media: media)
            }
          }
          
          
        }
      }
//    }
//  else {
//      guard let media = mediaObj else { return }
//      self.gifImageView.media = media
//    }
  }
  
  func playGifAnimation(media: GPHMedia) {
    
    guard let gifURL = media.url(rendition: .fixedWidth, fileType: .mp4) else { return  }
    guard let url = URL(string: gifURL) else {
      return
    }
    let asset = AVAsset.init(url: url)
    let duration = asset.duration
    let totalSeconds = CMTimeGetSeconds(duration)
    let seconds = totalSeconds.truncatingRemainder(dividingBy: 60)

    self.gifImageView.animationDuration = seconds
    self.gifImageView.animationRepeatCount = 1
    self.gifImageView.startAnimating()
    
    Timer.scheduledTimer(timeInterval: seconds, target: self, selector: #selector(timerStop), userInfo: nil, repeats: false)
  }
  
  @objc func timerStop() {
    placeHolderGifImage.isHidden = false
    self.gifImageView.stopAnimating()
  }
  
  @objc
  func imageTapped(gestureRecognizer: UITapGestureRecognizer) {
    isAlreadyLoaded = false
    playGifImageOnceGain()
  }
  
  func playGifImageOnceGain() {
    guard let media = mediaObj else {
      return
    }
    placeHolderGifImage.isHidden = true
    playGifAnimation(media: media)
  }
  
}
