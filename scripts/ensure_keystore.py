import os
import subprocess

def ensure_keystore():
    keystore_path = "android/app/debug.keystore"
    if not os.path.exists(keystore_path):
        print("Keystore not found. Generating a new one for build consistency...")

        storepass = os.environ.get("KEYSTORE_STOREPASS")
        keypass = os.environ.get("KEYSTORE_KEYPASS")

        if not storepass or not keypass:
            raise ValueError("Environment variables KEYSTORE_STOREPASS and KEYSTORE_KEYPASS must be set.")

        cmd = [
            "keytool", "-genkey", "-v",
            "-keystore", keystore_path,
            "-alias", "androiddebugkey",
            "-storepass", storepass,
            "-keypass", keypass,
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "10000",
            "-dname", "CN=Android Debug,O=Android,C=US"
        ]
        subprocess.run(cmd, check=True)
        print(f"Generated keystore at {keystore_path}")
    else:
        print("Keystore already exists.")

if __name__ == "__main__":
    ensure_keystore()
