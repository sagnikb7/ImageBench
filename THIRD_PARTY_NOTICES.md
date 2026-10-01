# Third-Party Notices

ImageBench bundles the following third-party components in release applications. They run locally and are not contacted as network services.

## Fraunces and Figtree

ImageBench uses Fraunces only for the wordmark and Figtree for interface headings and text. Both upright variable fonts are bundled locally under the SIL Open Font License 1.1, with no runtime font downloads.

- [Fraunces source](https://github.com/google/fonts/tree/main/ofl/fraunces): bundled as `Fraunces.ttf`; SHA-256 `177ff6c0f14e5550a3c624247cd1189611d4eb65d000b14944c63d967958abbb`.
- [Figtree source](https://github.com/google/fonts/tree/main/ofl/figtree): bundled as `Figtree.ttf`; SHA-256 `26ad3db9b31ff7dde67a91ff515d022d2f495cd506590699cf264f0bfe6fb714`.

The complete licenses are included in `ImageBench.app/Contents/Resources/Licenses/Fraunces-OFL.txt` and `Figtree-OFL.txt`. Original copyright notices are retained in those files.

## mozjpeg 4.1.5

ImageBench uses the `cjpeg` encoder from Mozilla's mozjpeg project, which is derived from libjpeg-turbo and Independent JPEG Group software. mozjpeg/libjpeg-turbo is distributed under compatible BSD-style, IJG, and zlib licenses.

This software is based in part on the work of the Independent JPEG Group.

The dependency build copies the upstream `LICENSE.md` into `Vendor/Tools/licenses/mozjpeg-LICENSE.md`, and the app packager includes it in `ImageBench.app/Contents/Resources/Licenses`.

[Upstream source](https://github.com/mozilla/mozjpeg)

Pinned source archive SHA-256: `9fcbb7171f6ac383f5b391175d6fb3acde5e64c4c4727274eade84ed0998fcc1`

## ExifTool 13.25

ExifTool is copyright Phil Harvey. It is free software distributed under the same terms as Perl itself: either the Perl Artistic License or the GNU General Public License.

The dependency build copies the upstream README containing its copyright and license statement into `Vendor/Tools/licenses/exiftool-README`, and the app packager includes it in `ImageBench.app/Contents/Resources/Licenses`.

Upstream: [ExifTool website](https://exiftool.org/) and [source repository](https://github.com/exiftool/exiftool)

Pinned source archive SHA-256: `90ff1b1fa214215f30fa547a8f0d53e7355d995426e3102ef6c6020dd3efbb04`

## Apple frameworks

ImageBench uses macOS system frameworks including SwiftUI, AppKit, Core Image, ImageIO, and Foundation. These are supplied by macOS and are not redistributed by this repository.
