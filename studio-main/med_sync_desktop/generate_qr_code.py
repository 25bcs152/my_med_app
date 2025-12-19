import qrcode
import sys

url = "https://www.mediafire.com/file/9wjusu3045s12tp/app-release.apk/file"
output_file = "apk_download_qr.png"

try:
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(output_file)
    print(f"QR code generated successfully: {output_file}")
except ImportError:
    print("Error: 'qrcode' library not found. Please run: pip install qrcode[pil]")
except Exception as e:
    print(f"Error generating QR code: {e}")
