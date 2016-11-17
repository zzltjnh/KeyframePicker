# KeyframePicker

Keyframe image picker like iPhone photo library written in Swift

## Example

To run the example project, clone the repo, open `KeyframePicker.xcworkspace` from root directory.

## Requirements

- iOS 8.0+
- Xcode 8.0
- Swift 3.0

## Installation

KeyframePicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

``` ruby
pod 'KeyframePicker'

```
## Usage

```swift
import KeyframePicker
```
```siwft
let storyBoard = UIStoryboard(name: "KeyframePicker", bundle: Bundle(for: KeyframePickerViewController.self))
                let keyframePicker = storyBoard.instantiateViewController(withIdentifier: String(describing: KeyframePickerViewController.self)) as! KeyframePickerViewController
                keyframePicker.asset = yourAvAsset
                // set handler
                keyframePicker.generatedKeyframeImageHandler = { [weak self] image in
                    if let image = image {
                        print("generate image success")
                    } else {
                        print("generate image failed")
                    }
                }
                self?.navigationController?.pushViewController(keyframePicker, animated: true)
 ``` 
## Author

Zhilong Zhang,Tianjin China, zzltjnh@gmail.com

## License

KeyframePicker is available under the MIT license. See the LICENSE file for more info.




