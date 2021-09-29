/*===============================================================================
Copyright (c) 2020, PTC Inc. All rights reserved.
 
Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.
===============================================================================*/

#include <metal_stdlib>
using namespace metal;

// === Texture sampling shader ===
struct VertexTextureOut
{
    float4 m_Position [[ position ]];
    float2 m_TexCoord;
};

vertex VertexTextureOut texturedVertex(constant packed_float3* pPosition   [[ buffer(0) ]],
                                constant float4x4*      pMVP        [[ buffer(1) ]],
                                constant float2*        pTexCoords  [[ buffer(2) ]],
                                uint                    vid         [[ vertex_id ]])
{
    VertexTextureOut out;
    float4 in(pPosition[vid], 1.0f);

    out.m_Position = *pMVP * in;
    out.m_TexCoord = pTexCoords[vid];

    return out;
}

fragment half4 texturedFragment(VertexTextureOut    inFrag  [[ stage_in ]],
                                texture2d<half>     tex2D   [[ texture(0) ]],
                                sampler             sampler2D [[ sampler(0) ]])
{
    return tex2D.sample(sampler2D, inFrag.m_TexCoord);
}


// === Uniform color shader ===
struct VertexOut
{
    float4 m_Position [[ position ]];
};

vertex VertexOut uniformColorVertex(constant packed_float3* pPosition   [[ buffer(0) ]],
                                         constant float4x4*      pMVP        [[ buffer(1) ]],
                                         uint                    vid         [[ vertex_id ]])
{
    VertexOut out;
    float4 in(pPosition[vid], 1.0f);
    
    out.m_Position = *pMVP * in;
    
    return out;
}

fragment float4 uniformColorFragment(constant float4 &color [[ buffer(0) ]])
{
    return color;
}


// === Vertex color shader ===
struct VertexColorOut
{
    float4 m_Position [[ position ]];
    float4 m_Color;
};

vertex VertexColorOut vertexColorVertex(constant packed_float3* pPosition   [[ buffer(0) ]],
                                        constant float4*        pColor      [[ buffer(1) ]],
                                        constant float4x4*      pMVP        [[ buffer(2) ]],
                                        uint                    vid         [[ vertex_id ]])
{
    VertexColorOut out;
    float4 in(pPosition[vid], 1.0f);
    
    out.m_Position = *pMVP * in;
    out.m_Color = pColor[vid];
    
    return out;
}

fragment float4 vertexColorFragment(VertexColorOut inFrag  [[ stage_in ]])
{
    return inFrag.m_Color;
}
