import os

abs_path = os.path.dirname(__file__)
rel_path = "convert"
full_path = os.path.join(abs_path, rel_path)

out =[]

def twos(decimal_num):
    if decimal_num < 0:
        decimal_num = (1 << 32) + decimal_num  # Convert to equivalent positive number in two's complement form
    binary_str = bin(decimal_num)[2:].zfill(32)  # Convert to binary string and pad with zeroes to 32 bits
    return binary_str

def convert(A, B, C):
    with open(A, "r") as f1:
        lines = f1.readlines()
        L1 = []
        for line in lines:
            L1 = line.strip().split(';')
            for i in range(len(L1)):
                L1[i] = twos(int(L1[i]))
                out.append(L1[i])
        
    with open(B, "r") as f2:
        lines = f2.readlines()
        L2 = []
        for line in lines:
            L2 = line.strip().split(';')
            for i in range(len(L2)):
                L2[i] = twos(int(L2[i]))
                out.append(L2[i])
        
    with open(C, "w") as res:
        for i in range(len(out) - 1):
            res.write(out[i] + '\n')
        res.write(out[-1])
    
convert("convert/A_100x50.txt", "convert/B_50x2.txt", "convert/../simulation/DMemory.txt")