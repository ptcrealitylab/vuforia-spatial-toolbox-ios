/**
 * FIXME Vuforia copyright header
 */

#pragma once

#include <stddef.h>

// FIXME proper exports header
#if _MSC_VER && defined(CAFFE2_C_EXPORTS)
#define CAFFE2_C_API __declspec(dllexport)
#else
// __declspec(dllimport) is optional now
#define CAFFE2_C_API
#endif

extern "C" {
    CAFFE2_C_API void*        caffe2_create_predictor();
    CAFFE2_C_API void         caffe2_destroy_predictor(void const* pred);
    CAFFE2_C_API bool         caffe2_set_init_net(void* pred, void* data, size_t size_bytes);
    CAFFE2_C_API bool         caffe2_set_predict_net(void* pred, void* data, size_t size_bytes);
    CAFFE2_C_API bool         caffe2_init_predictor(void* pred);
    CAFFE2_C_API bool         caffe2_do_prediction(void* pred, float const* data, size_t num_channels, size_t num_rows, size_t num_cols);
    CAFFE2_C_API float const* caffe2_get_last_prediction_result(void* pred);
    CAFFE2_C_API size_t       caffe2_get_last_prediction_result_size(void* pred);
}
