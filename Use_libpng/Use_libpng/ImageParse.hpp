//
//  ImageParse.hpp
//  Use_libpng
//
//  Created by 黄世平 on 2022/3/19.
//

#ifndef ImageParse_hpp
#define ImageParse_hpp

#include <stdio.h>

class ImageParse {
public:
  ImageParse();
  void LoadPngData(const unsigned char* data, ssize_t dataLen);
  unsigned char* GetData() { return data_; }
  ssize_t GetDataLen() { return dataLen_; }
  int GetWidth() { return width_; }
  int GetHeight() { return height_;}
private:
  unsigned char *data_;
  ssize_t dataLen_;
  int width_;
  int height_;
private:
  void PremultipliedAlpha();
};

#endif /* ImageParse_hpp */
