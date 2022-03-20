//
//  ImageParse.cpp
//  Use_libpng
//
//  Created by 黄世平 on 2022/3/19.
//

#include "libpng/include/png.h"
#include "ImageParse.hpp"
#include <string>
#include <memory>

#define BREAK_IF(cond)           if(cond) break

#define RGB_PREMULTIPLY_ALPHA(vr, vg, vb, va) \
(unsigned)(((unsigned)((unsigned char)(vr) * ((unsigned char)(va) + 1)) >> 8) | \
((unsigned)((unsigned char)(vg) * ((unsigned char)(va) + 1) >> 8) << 8) | \
((unsigned)((unsigned char)(vb) * ((unsigned char)(va) + 1) >> 8) << 16) | \
((unsigned)(unsigned char)(va) << 24))

ImageParse::ImageParse()
: data_(nullptr)
, dataLen_(0)
, width_(0)
, height_(0) { }

typedef struct {
  const unsigned char * data;
  ssize_t size;
  int offset;
}tImageSource;

static void pngReadCallback(png_structp png_ptr, png_bytep data, png_size_t length) {
  tImageSource* isource = (tImageSource*)png_get_io_ptr(png_ptr);
  if((int)(isource->offset + length) <= isource->size) {
    memcpy(data, isource->data+isource->offset, length);
    isource->offset += length;
  } else {
    printf("png reader callback is failed. \n");
  }
}

void ImageParse::LoadPngData(const unsigned char* data, ssize_t dataLen) {
#define PNGSIGSIZE  8
  bool ret = false;
  png_byte        header[PNGSIGSIZE]   = {0};
  png_structp     png_ptr     =   0;
  png_infop       info_ptr    = 0;
  do {
    BREAK_IF(dataLen < PNGSIGSIZE);
    memcpy(header, data, PNGSIGSIZE);
    if (png_sig_cmp(header, 0, PNGSIGSIZE)) {
        printf("png read png header is error. \n");
    }
    BREAK_IF(png_sig_cmp(header, 0, PNGSIGSIZE));
    png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
    BREAK_IF(!png_ptr);
    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr) {
        printf("png read info is error. \n");
    }
    BREAK_IF(!info_ptr);
    tImageSource imageSource;
    imageSource.data    = (unsigned char*)data;
    imageSource.size    = dataLen;
    imageSource.offset  = 0;
    png_set_read_fn(png_ptr, &imageSource, pngReadCallback);
    png_read_info(png_ptr, info_ptr);
    width_ = png_get_image_width(png_ptr, info_ptr);
    height_ = png_get_image_height(png_ptr, info_ptr);
    png_byte bit_depth = png_get_bit_depth(png_ptr, info_ptr);
    png_uint_32 color_type = png_get_color_type(png_ptr, info_ptr);
    if (color_type == PNG_COLOR_TYPE_PALETTE) {
      png_set_palette_to_rgb(png_ptr);
    }
    if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) {
      bit_depth = 8;
      png_set_expand_gray_1_2_4_to_8(png_ptr);
    }
    if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS)) {
      png_set_tRNS_to_alpha(png_ptr);
    }
    if (bit_depth == 16) {
      png_set_strip_16(png_ptr);
    }
    if (bit_depth < 8) {
      png_set_packing(png_ptr);
    }
    png_read_update_info(png_ptr, info_ptr);
    color_type = png_get_color_type(png_ptr, info_ptr);
    switch (color_type) {
      case PNG_COLOR_TYPE_GRAY:
      case PNG_COLOR_TYPE_GRAY_ALPHA:
      case PNG_COLOR_TYPE_RGB:
      case PNG_COLOR_TYPE_RGB_ALPHA:
        //TODO:更新ColorType
        break;
      default:
        break;
    }
    png_size_t rowbytes;
    int bytep_length = sizeof(png_bytep) * height_;
    png_bytep* row_pointers = (png_bytep*)malloc(bytep_length);
    if(row_pointers == NULL) {
        printf("row_pointers is null. \n");
    }
    rowbytes = png_get_rowbytes(png_ptr, info_ptr);
    dataLen_ = rowbytes * height_;
    int length = (int) (dataLen_ * sizeof(unsigned char));
    data_ = static_cast<unsigned char*>(malloc(length));
    if(data_ == NULL) {
        printf("png data is null. \n");
    }
    if (!data_) {
      if (row_pointers != nullptr) {
        free(row_pointers);
      }
      break;
    }
    for (unsigned short i = 0; i < height_; ++i) {
      row_pointers[i] = data_ + i*rowbytes;
    }
    // read png data
    png_read_image(png_ptr, row_pointers);
    png_read_end(png_ptr, nullptr);
    //premultiplied alpha for RGBA8888
    if(dataLen_ / width_ / height_ == 4) {
      PremultipliedAlpha();
    }
    if (row_pointers != nullptr) {
      free(row_pointers);
    }
    ret = true;
  } while (0);
  if (png_ptr) {
    png_destroy_read_struct(&png_ptr, (info_ptr) ? &info_ptr : 0, 0);
  }
}

void ImageParse::PremultipliedAlpha() {
  unsigned int* fourBytes = (unsigned int*)data_;
  for(int i = 0; i < width_ * height_; i++) {
    unsigned char* p = data_ + i * 4;
    fourBytes[i] = RGB_PREMULTIPLY_ALPHA(p[0], p[1], p[2], p[3]);
  }
}

