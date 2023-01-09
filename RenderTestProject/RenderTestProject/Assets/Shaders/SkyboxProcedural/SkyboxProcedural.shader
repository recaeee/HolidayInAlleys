Shader "Render Test/Skybox Procedural"
{
    Properties
    {
        //【地平线】
        [Header(Horizon)]
        _HorizonOffset("Horiziont Offset",Range(-1,1)) = 0
        _HorizonIntensity("Horizon Intensity",Range(0,10)) = 7
        _HorizonBloom("Horizon Bloom",Range(1,10)) = 3
        _HorizonAuroraIntensity("Horizon Aurora Intensity",Range(0,10)) = 1
        _HorizonAuroraSmooth("Horizon Aurora Smooth",Range(0,1)) = 0.05
        _HorizonAuroraBloom("Horizon Aurora Bloom",Range(0,10)) = 1
        //【白天】
        [Header(Day)]
        _DayBottomColor("Day Bottom Color",Color) = (1,1,1,1)
        _DayTopColor("Day Top Color",Color) = (1,1,1,1)
        _DayHorizonColor("Day Horizon Color",Color) = (1,1,1,1)
        _DayCloudColor("Day Cloud Color",Color) = (1,1,1,1)
        _DayCloudBloom("Day Cloud Bloom", Range(0,10)) = 2
        _DayTopIntensity("Day Top Intensity",Range(0,10)) = 4
        //【黑夜】
        [Header(Night)]
        _NightBottomColor("Night Bottom Color",Color) = (0,0,0,1)
        _NightTopColor("Night Top Color",Color) = (0,0,0,1)
        _NightHorizonColor("Night Horizon Color",Color) = (0,0,0,1)
        _NightCloudColor("Night Cloud Color",Color) = (0,0,0,1)
        _NightCloudBloom("Night Cloud Bloom",Range(0,10)) = 0.5
        _NightTopIntensity("Night Top Intensity",Range(0,10)) = 1
        //【云】
        [Header(Cloud)]
        //云主噪声
        _CloudBaseNoiseTex("Cloud Base Noise Tex",2D) = "black" {}
        //云主噪声速度
        _CloudBaseNoiseSpeed("Cloud Base Noise Speed",Range(0,1)) = 0.1
        //云主噪声强度
        _CloudBaseNoiseIntensity("Cloud Base Noise Intensity",Range(0,3)) = 0.2
        //云噪声扰动
        _CloudDistortTex("Cloud Distort Tex",2D) = "black" {}
        //云噪声扰动速度
        _CloudDistortSpeed("Could Distort Speed",Range(0,1)) = 0.1
        //云噪声扰动强度
        _CouldDistortIntensity("Cloud Distort Intensity",Range(0,3)) = 1
        //云副噪声
        _CloudSecondaryNoiseTex("Cloud Secondary Noise Tex",2D) = "black" {}
        //云副噪声扰动速度
        _CloudSecondaryNoiseSpeed("Cloud Secondary Noise Speed",Range(0,1)) = 0.1
        //云副噪声强度
        _CloudSecondaryNoiseIntensity("Cloud Secondary Noise Intensity",Range(0,3)) = 0.05
        //云裁剪值
        _CloudCutoff("Cloud Cutoff",Range(0,1)) = 0.08
        //云裁剪模糊
        _CloudFuzziness("Cloud Fuzziness",Range(0,0.1)) = 0.015
        //远处云消散
        _CloudDissipate("Cloud Dissipate",Range(0,1)) = 0.08
        [Header(Star)]
        //【星】
        _StarNoiseTex("Star Noise Tex",2D) = "black" {}
        _StarIntensity("Star Intensity",Range(0,10)) = 1
        _StarBloom("Star Bloom",Range(0,10)) = 2
        _StarSpeed("Star Speed",Range(0,1)) = 0.1
        _StarCutoff("Star Cutoff",Range(0,1)) = 0.05
        _StarColor("Star Color",Color) = (1,1,1,1)
    }
    Subshader
    {
        Pass
        {
            Tags
            {
                "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "False"
            }

            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float _HorizonOffset, _HorizonIntensity, _HorizonBloom, _HorizonAuroraIntensity, _HorizonAuroraBloom, _HorizonAuroraSmooth;
            float4 _DayBottomColor, _DayTopColor, _DayHorizonColor, _DayCloudColor;
            float _DayCloudBloom, _DayTopIntensity;
            float4 _NightBottomColor, _NightTopColor, _NightHorizonColor, _NightCloudColor;
            float _NightCloudBloom, _NightTopIntensity;
            float _CloudBaseNoiseSpeed, _CloudBaseNoiseIntensity, _CloudDistortSpeed;
            float _CloudDistortIntensity, _CloudSecondaryNoiseSpeed, _CloudSecondaryNoiseIntensity;
            float _CloudCutoff, _CloudFuzziness,_CloudDissipate;
            float4 _StarColor;
            float _StarIntensity, _StarBloom, _StarSpeed, _StarCutoff;
            
            TEXTURE2D(_CloudBaseNoiseTex);SAMPLER(sampler_CloudBaseNoiseTex);
            TEXTURE2D(_CloudDistortTex);SAMPLER(sampler_CloudDistortTex);
            TEXTURE2D(_CloudSecondaryNoiseTex);SAMPLER(sampler_CloudSecondaryNoiseTex);
            TEXTURE2D(_StarNoiseTex);SAMPLER(sampler_StarNoiseTex);

            struct appdata
            {
                float4 vertex : POSITION;
                //Cubemap的uv坐标为float3
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 uv : TEXCOORD0;
                float3 worldPos : TEXCOOORD1;
            };

            float3 SkyAurora(float3 pos,float3 ro)
            {
                float3 col = float3(0,0,0);
                float3 avgCol = float3(0,0,0);
                float3 skyAuroraColor = float3(0,0,0);

                for(int i=0;i<60;i++)
                {
                    float of = 0.06 * SAMPLE_TEXTURE2D(_CloudDistortTex,sampler_CloudDistortTex,pos.xy) * smoothstep(0,15,i);
                    float pt = ((0.8+pow(i,1.4) * 0.002) -ro.y)/(pos.y*2.0+0.8);
                    pt -= of;
                    float3 bpos = ro +pt*pos;
                    float2 p = bpos.zx;

                    float noise = SAMPLE_TEXTURE2D(_CloudDistortTex,sampler_CloudDistortTex,p);
                    float3 col2 = float3(0,0,0);
                    col2.rgb = (sin(1.0-float3(2.15,-0.5,1.2)+ i + 1 * 0.1)*0.8+0.5)*noise;
                    avgCol = lerp(avgCol,col2,0.5);
                    col += avgCol *exp2(-i*0.065-2.5)*smoothstep(0,5,i);
                }

                col *=(clamp(pos.y * 15+4,0,1));
                return col * 1.8;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                return o;
            }

            //saturate(x):将x夹到[0,1]内
            //Step(a,x):如果x<a返回0；如果x>或=a返回1
            //SmoothStep(a,b,x):x<=a返回0；a<x<b返回0到1的平滑过度；x>=b返回1

            float4 frag(v2f i) : SV_TARGET
            {
                float3 finalColor = float3(0,0,0);
                //获取方向光
                Light mainLight = GetMainLight();
                float dayTime = saturate(mainLight.direction.y);
                //【纹理坐标】
                float2 skyboxUV = i.worldPos.xz / i.worldPos.y;
                //【渐变颜色】
                float3 gradientDayColor = lerp(_DayBottomColor,_DayTopColor,saturate(i.uv.y * _DayTopIntensity));
                float3 gradientNightColor = lerp(_NightBottomColor,_NightTopColor,saturate(i.uv.y * _NightTopIntensity));
                float3 gradientSkyColor = lerp(gradientNightColor,gradientDayColor,dayTime);
                //【地平线】
                float horizon =  abs(i.uv.y * _HorizonIntensity - _HorizonOffset);
                float horizonReverse = saturate(1-horizon*3);
                float3 horizonColor = horizonReverse * lerp(_NightHorizonColor,_DayHorizonColor,dayTime) * _HorizonBloom;
                //【云】
                float cloudDistort = SAMPLE_TEXTURE2D(_CloudDistortTex, sampler_CloudDistortTex,
                                                      (skyboxUV + _Time.x * _CloudDistortSpeed) * _CloudDistortIntensity);
                float cloudBaseNoise = SAMPLE_TEXTURE2D(_CloudBaseNoiseTex, sampler_CloudBaseNoiseTex,
                                                        (skyboxUV + cloudDistort - _Time.x * _CloudBaseNoiseSpeed) * _CloudBaseNoiseIntensity);
                float cloudSecondaryNoise = SAMPLE_TEXTURE2D(_CloudSecondaryNoiseTex,sampler_CloudSecondaryNoiseTex,(skyboxUV + cloudBaseNoise - _Time.x * _CloudSecondaryNoiseSpeed)  * _CloudSecondaryNoiseIntensity);
                
                float finalNoise = saturate(cloudBaseNoise * cloudSecondaryNoise) * smoothstep(_CloudDissipate,_CloudDissipate + 0.005,i.uv.y);

                float cloud = smoothstep(_CloudCutoff,_CloudCutoff+_CloudFuzziness,finalNoise);

                float3 cloudColor = cloud * lerp(_NightCloudColor * _NightCloudBloom,_DayCloudColor * _DayCloudBloom, dayTime);
                //【星】
                float3 star = SAMPLE_TEXTURE2D(_StarNoiseTex,sampler_StarNoiseTex,(skyboxUV + _Time.x * _StarSpeed) * _StarIntensity);
                float3 starColor = step(_StarCutoff, star) * _StarColor * _StarBloom * (1 - cloud) * (1 - dayTime) * saturate(i.worldPos.y);
                //【地平线极光】
                float3 horizonAuroraColor = (smoothstep(-_HorizonAuroraIntensity,-_HorizonAuroraIntensity+_HorizonAuroraSmooth,-horizon)+smoothstep(-_HorizonAuroraIntensity,-_HorizonAuroraIntensity+_HorizonAuroraSmooth,horizon) - 1) * (1,1,1,1) * _HorizonAuroraBloom;
                //【天空极光】
                float3 skyAuroraColor = SkyAurora(i.uv,float3(1,0,0)).x/15 * float3(0,1,0);
                // skyAuroraColor = smoothstep(0.5,0.8,skyAuroraColor);
                // return float4(skyAuroraColor,1);
                //【最终颜色】
                finalColor = gradientSkyColor + horizonColor + cloudColor + starColor + horizonAuroraColor + skyAuroraColor;
                return float4(finalColor, 1);
            }
            ENDHLSL
        }
    }
}
