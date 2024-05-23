# This script generates header for Extension Module Descriptors and then serialize the header and the Extension Module Descriptor
# into a binary file in order to be downloaded to the EEPROM can be found on the extension module PCB.

import os
import hashlib
import json

def calculate_md5(file_path):
    """Calculates the MD5 checksum of a file."""
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def get_file_size(file_path):
    """Returns the size of the file in bytes."""
    return os.path.getsize(file_path)

def process_files(directory):
    """Processes all JSON files in the specified directory and creates binary files with JSON metadata and file content."""
    for filename in os.listdir(directory):
        if filename.endswith('.json'):
            file_path = os.path.join(directory, filename)
            if os.path.isfile(file_path):
                md5_checksum = calculate_md5(file_path)
                file_size = get_file_size(file_path)
                file_info = {
                    "MD5": md5_checksum,
                    "SIZE": file_size
                }
                json_string = json.dumps(file_info)
                json_bytes = json_string.encode('utf-8')

                new_file_path = os.path.join(directory, f"{filename}.bin")
                with open(new_file_path, 'wb') as new_file:
                    # Write the JSON bytes followed by spaces to reach the 64th byte
                    new_file.write(json_bytes)
                    new_file.write(b' ' * (64 - len(json_bytes)))

                    # Write the original file content starting at the 64th byte
                    with open(file_path, 'rb') as original_file:
                        new_file.write(original_file.read())

if __name__ == "__main__":
    directory = 'ext_module_descriptors'
    process_files(directory)
    print("JSON files have been processed and saved with .bin extension")
