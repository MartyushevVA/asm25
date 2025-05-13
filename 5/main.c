#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma pack(push, 1)
typedef struct {
    char signature[2];
    unsigned int fileSize;
    unsigned int reserved;
    unsigned int dataOffset;
    unsigned int headerSize;
    int width;
    int height;
    unsigned short planes;
    unsigned short bitsPerPixel;
    unsigned int compression;
    unsigned int imageSize;
    int xPixelsPerMeter;
    int yPixelsPerMeter;
    unsigned int colorsUsed;
    unsigned int colorsImportant;
} BMPHeader;
#pragma pack(pop)

void processImageC(unsigned char* image, int width, int height, int channel);
extern void processImageASM(unsigned char* image, int width, int height, int channel);

int main(int argc, char* argv[]) {
    if (argc != 5) {
        printf("Usage: %s <input.bmp> <output.bmp> <channel: 0-R, 1-G, 2-B> <mode: 0-C, 1-ASM>\n", argv[0]);
        return 1;
    }

    int channel = atoi(argv[3]);
    int mode = atoi(argv[4]);

    if (channel < 0 || channel > 2 || mode < 0 || mode > 1) {
        printf("Invalid parameters. Channel must be 0-2, mode must be 0-1\n");
        return 1;
    }

    FILE* input = fopen(argv[1], "rb");
    if (!input) {
        printf("Error opening input file\n");
        return 1;
    }

    BMPHeader header;
    fread(&header, sizeof(BMPHeader), 1, input);

    if (header.bitsPerPixel != 24) {
        printf("Only 24-bit BMP images are supported\n");
        fclose(input);
        return 1;
    }

    unsigned char* imageData = (unsigned char*)malloc(header.imageSize);
    fseek(input, header.dataOffset, SEEK_SET);
    fread(imageData, 1, header.imageSize, input);
    fclose(input);

    // Process image
    if (mode == 0) {
        processImageC(imageData, header.width, header.height, channel);
    } else {
        processImageASM(imageData, header.width, header.height, channel);
    }

    FILE* output = fopen(argv[2], "wb");
    if (!output) {
        printf("Error creating output file\n");
        free(imageData);
        return 1;
    }

    fwrite(&header, sizeof(BMPHeader), 1, output);
    fseek(output, header.dataOffset, SEEK_SET);
    fwrite(imageData, 1, header.imageSize, output);
    fclose(output);
    free(imageData);

    printf("Image processed successfully\n");
    return 0;
}

void processImageC(unsigned char* image, int width, int height, int channel) {
    int padding = (4 - (width * 3) % 4) % 4;
    int rowSize = width * 3 + padding;

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int offset = y * rowSize + x * 3;
            unsigned char gray = image[offset + channel];
            image[offset] = gray;     // B
            image[offset + 1] = gray; // G
            image[offset + 2] = gray; // R
        }
    }
}