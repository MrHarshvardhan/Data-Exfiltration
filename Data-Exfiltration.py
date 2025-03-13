import os
import argparse
import random
import string
import base64

def generate_key(length=10):
    """Generate a random encryption key."""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def xor_encrypt_decrypt(content_bytes, key):
    """Perform XOR encryption/decryption on binary data."""
    key_bytes = key.encode()  # Convert key to bytes
    return bytes([content_bytes[i] ^ key_bytes[i % len(key_bytes)] for i in range(len(content_bytes))])

def split_file(content, part_size):
    """Split content into parts of specified size."""
    return [content[i:i+part_size] for i in range(0, len(content), part_size)]

def merge_parts(folder, filename, total_parts):
    """Merge file parts into a single content string."""
    full_content = ""
    for idx in range(1, total_parts + 1):
        part_filename = f"{filename}_part{idx}.txt"
        part_path = os.path.join(folder, part_filename)
        if not os.path.exists(part_path):
            print(f"Error: Missing part {idx} for file {filename}")
            return None
        with open(part_path, 'r', encoding='utf-8') as f:
            full_content += f.read()
    return full_content

def encode_files(folder, part_size=500000):  # Default part size ~500KB
    """Encode files into encrypted Base64 split text parts."""
    for file in os.listdir(folder):
        file_path = os.path.join(folder, file)
        if os.path.isfile(file_path):
            with open(file_path, 'rb') as f:
                binary_content = f.read()  # Read file as binary
            
            key = generate_key()
            encrypted_content = xor_encrypt_decrypt(binary_content, key)  # Encrypt
            
            # Convert encrypted binary to Base64 string
            encoded_base64 = base64.b64encode(encrypted_content).decode()

            parts = split_file(encoded_base64, part_size)
            base_name = os.path.splitext(file)[0]
            
            for idx, part in enumerate(parts):
                part_filename = os.path.join(folder, f"{base_name}_part{idx+1}.txt")
                with open(part_filename, 'w', encoding='utf-8') as f:
                    if idx == 0:
                        f.write(f"{os.path.splitext(file)[1]}\n{key}\n")  # Store extension and key in the first part
                    f.write(part)  # Write Base64-encoded encrypted content
            
            print(f"Encoded: {file} -> {len(parts)} parts")

def decode_files(folder):
    """Decode encrypted text parts back into original files."""
    decoded_files = {}
    for file in os.listdir(folder):
        if file.endswith('.txt') and os.path.isfile(os.path.join(folder, file)):
            base_name = file.rsplit('_part', 1)[0]  # Extract base filename
            part_num = int(file.rsplit('_part', 1)[1].split('.')[0])
            if base_name not in decoded_files:
                decoded_files[base_name] = []
            decoded_files[base_name].append((part_num, file))
    
    for base_file, parts in decoded_files.items():
        parts.sort()  # Ensure correct order
        total_parts = len(parts)
        full_content = merge_parts(folder, base_file, total_parts)
        
        if full_content is None:
            continue
        
        lines = full_content.split('\n', 2)
        original_extension = lines[0].strip()  # Read stored extension
        key = lines[1].strip()  # Read stored key

        # Extract Base64 Encrypted Data
        encrypted_base64 = lines[2] if len(lines) > 2 else ""
        
        # Convert Base64 back to encrypted bytes
        encrypted_bytes = base64.b64decode(encrypted_base64)

        # XOR Decrypt
        decrypted_content = xor_encrypt_decrypt(encrypted_bytes, key)

        # Restore the original file
        original_filename = os.path.join(folder, base_file + original_extension)
        with open(original_filename, 'wb') as f:
            f.write(decrypted_content)

        print(f"Restored: {base_file} -> {original_filename}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert files to disguised .txt parts and restore them back.")
    parser.add_argument("folder", help="Path to the folder containing files")
    parser.add_argument("--decode", action="store_true", help="Use this flag to restore files")
    
    args = parser.parse_args()
    
    if args.decode:
        decode_files(args.folder)
    else:
        encode_files(args.folder)
