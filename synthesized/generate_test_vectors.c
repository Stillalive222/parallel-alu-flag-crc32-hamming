// generate_test_vectors.c
#include <stdio.h>
#include <stdint.h>

// CRC32 lookup table
uint32_t crc32_table[256];

void init_crc32_table() {
    for (int i = 0; i < 256; i++) {
        uint32_t crc = i;
        for (int j = 0; j < 8; j++) {
            crc = (crc >> 1) ^ (0xEDB88320 & -(crc & 1));
        }
        crc32_table[i] = crc;
    }
}

uint32_t calculate_crc32(uint8_t *data, size_t len) {
    uint32_t crc = 0xFFFFFFFF;
    for (size_t i = 0; i < len; i++) {
        crc = (crc >> 8) ^ crc32_table[(crc ^ data[i]) & 0xFF];
    }
    return ~crc;
}

// Hamming code generator
uint32_t generate_hamming(uint32_t data) {
    uint32_t encoded = 0;
    // Simplified Hamming encoding (you can expand this)
    // This is a demonstration of the algorithm
    return encoded;
}

int main() {
    init_crc32_table();
    
    FILE *fp = fopen("C:\\Users\\kanmo\\Desktop\\co project\\test_vectors.txt", "w");
    if (!fp) {
        printf("Error opening file!\n");
        return 1;
    }
    
    fprintf(fp, "// Test vectors for Verilog testbench\n");
    fprintf(fp, "// Format: Input_Data, Expected_CRC32, Expected_Hamming\n\n");
    
    // Test cases matching your Verilog tests
    uint32_t test_data[] = {
        0x00000000,
        0xFFFFFFFF,
        0x12345678,
        0xDEADBEEF,
        0xAAAAAAAA,
        0x55555555
    };
    
    for (int i = 0; i < 6; i++) {
        uint8_t *bytes = (uint8_t*)&test_data[i];
        uint32_t crc = calculate_crc32(bytes, 4);
        
        fprintf(fp, "Test %d:\n", i+1);
        fprintf(fp, "  Input:    0x%08X\n", test_data[i]);
        fprintf(fp, "  CRC32:    0x%08X\n", crc);
        fprintf(fp, "  Binary:   ");
        
        for (int j = 31; j >= 0; j--) {
            fprintf(fp, "%d", (test_data[i] >> j) & 1);
            if (j % 8 == 0) fprintf(fp, " ");
        }
        fprintf(fp, "\n\n");
    }
    
    // Generate Verilog task calls
    fprintf(fp, "\n// Verilog testbench task calls:\n");
    for (int i = 0; i < 6; i++) {
        uint8_t *bytes = (uint8_t*)&test_data[i];
        uint32_t crc = calculate_crc32(bytes, 4);
        fprintf(fp, "calculate_crc(32'h%08X, 32'h%08X);\n", test_data[i], crc);
    }
    
    fclose(fp);
    printf("Test vectors generated successfully!\n");
    printf("File saved to: C:\\Users\\kanmo\\Desktop\\co project\\test_vectors.txt\n");
    
    return 0;
}