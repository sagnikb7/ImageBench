# Third-Party Notices

ImageBench bundles the following third-party components in release applications. They run locally and are not contacted as network services.

## Archivo Narrow

The ImageBench wordmark uses Archivo Narrow by Omnibus-Type. The font is distributed under the SIL Open Font License, Version 1.1.

The app bundles the variable upright font and includes the complete license at `ImageBench.app/Contents/Resources/Licenses/ArchivoNarrow-OFL.txt`.

Upstream: https://github.com/Omnibus-Type/ArchivoNarrow

Pinned upstream commit: `9793ec77b6682a26bc7a6ed523ca65cc3cb90aec`

Bundled font SHA-256: `adbe027f625c8393ae0f6e174e32e233dda485bc3eda5153ce428275394ef97f`

## mozjpeg 4.1.5

ImageBench uses the `cjpeg` encoder from Mozilla's mozjpeg project, which is derived from libjpeg-turbo and Independent JPEG Group software. mozjpeg/libjpeg-turbo is distributed under compatible BSD-style, IJG, and zlib licenses.

This software is based in part on the work of the Independent JPEG Group.

The dependency build copies the upstream `LICENSE.md` into `Vendor/Tools/licenses/mozjpeg-LICENSE.md`, and the app packager includes it in `ImageBench.app/Contents/Resources/Licenses`.

Upstream: https://github.com/mozilla/mozjpeg

Pinned source archive SHA-256: `9fcbb7171f6ac383f5b391175d6fb3acde5e64c4c4727274eade84ed0998fcc1`

## ExifTool 13.25

ExifTool is copyright Phil Harvey. It is free software distributed under the same terms as Perl itself: either the Perl Artistic License or the GNU General Public License.

The dependency build copies the upstream README containing its copyright and license statement into `Vendor/Tools/licenses/exiftool-README`, and the app packager includes it in `ImageBench.app/Contents/Resources/Licenses`.

Upstream: https://exiftool.org/ and https://github.com/exiftool/exiftool

Pinned source archive SHA-256: `90ff1b1fa214215f30fa547a8f0d53e7355d995426e3102ef6c6020dd3efbb04`

## Apple frameworks

ImageBench uses macOS system frameworks including SwiftUI, AppKit, Core Image, ImageIO, and Foundation. These are supplied by macOS and are not redistributed by this repository.
