//
//  ImagePartSource.mm
//  RealityEditor
//
//  Created by James Hobin on 7/14/16.
//
//

#include "ImagePartSource.h"

ImagePartSource::ImagePartSource(const ofImage& image) : PartSource("image/jpeg") {
    ofSaveImage(image.getPixels(), _buf, OF_IMAGE_FORMAT_JPEG, OF_IMAGE_QUALITY_HIGH);
    _str.setData(_buf.getData(), _buf.getData() + _buf.size());
    _in = new istream(&_str);
}

istream& ImagePartSource::stream() {
    return *_in;
}

const string& ImagePartSource::filename() const {
    return _filename;
}

streamsize ImagePartSource::getContentLength() const {
    return _buf.size();
}

ImagePartSource::~ImagePartSource() {
    delete _in;
}
