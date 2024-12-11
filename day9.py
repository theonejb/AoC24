def parse_disk_map(disk_map):
    # Convert string like "2333" into list of alternating file/space lengths
    lengths = [int(x) for x in disk_map]
    
    # Create expanded representation with file IDs and spaces
    expanded = []
    file_id = 0
    
    for i, length in enumerate(lengths):
        if i % 2 == 0:  # File
            expanded.extend([file_id] * length)
            file_id += 1
        else:  # Space
            expanded.extend(['.'] * length)
            
    return expanded

def find_leftmost_space(disk):
    return disk.index('.') if '.' in disk else -1

def find_rightmost_file(disk):
    for i in range(len(disk)-1, -1, -1):
        if disk[i] != '.':
            return i
    return -1

def compact_disk(disk):
    while True:
        space_pos = find_leftmost_space(disk)
        if space_pos == -1:
            break
            
        file_pos = find_rightmost_file(disk)
        if file_pos < space_pos:
            break
            
        # Move one block from right to left
        disk[space_pos] = disk[file_pos]
        disk[file_pos] = '.'
    
    return disk

def calculate_checksum(disk):
    checksum = 0
    for pos, value in enumerate(disk):
        if value != '.':
            checksum += pos * value
    return checksum

def solve(disk_map):
    # Parse input
    disk = parse_disk_map(disk_map)
    
    # Compact the disk
    disk = compact_disk(disk)
    
    # Calculate and return checksum
    return calculate_checksum(disk)

# Test with example
test_input = open("./inputs/day9.txt").read()
result = solve(test_input)
print(f"Checksum: {result}")