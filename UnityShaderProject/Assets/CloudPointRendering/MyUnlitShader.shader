// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/MyUnlitShader"
{
    Properties
    {
        _Layer0("_Layer0", 2D) = "white" {}
		_Layer1("_Layer1", 2D) = "white" {}
		_Layer2("_Layer2", 2D) = "white" {}
		_Layer3("_Layer3", 2D) = "white" {}
		_Layer4("_Layer4", 2D) = "white" {}
		_Layer5("_Layer5", 2D) = "white" {}
		_Layer6("_Layer6", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
				float4 vertex : POSITION0;
				float4 color : COLOR;
				float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
				float4 vertex : POSITION0;
				float4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float3 screenpos : TEXCOORD1;
				float3 localPos : POSITION1;
			};

            sampler2D _Layer1;

			float4 _Layer1_ST;

			v2f vert(appdata IN)
			{
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color;
				OUT.screenpos = ComputeScreenPos(OUT.vertex);
				OUT.localPos = IN.vertex.xyz;

				return OUT;
			}

			float2 convertToUVLocation(int3 voxelIndex, int2 textureSize)
			{
				//uint voxelMemorySize = (4 * 4); // 4 bytes per component (one float) and [r, g, b, a]
				uint oneDimentionalLocation = (voxelIndex.x + voxelIndex.y + voxelIndex.z);
				uint rowCount = textureSize.x;

				uint yLocation = ceil(oneDimentionalLocation / rowCount);
				uint xLocation = ceil(oneDimentionalLocation % rowCount);

				return float2(float(xLocation) / textureSize.x, float(yLocation) / textureSize.y);
			}

            fixed4 frag (v2f IN) : COLOR
            {
				float3 cubeDimentions = float3(2.0, 2.0, 2.0);
				uint3 voxelIndex = int3(
					round((IN.localPos.x + (cubeDimentions.x / 2.0)) / cubeDimentions.x),
					round((IN.localPos.y + (cubeDimentions.y / 2.0)) / cubeDimentions.y),
					round((IN.localPos.z + (cubeDimentions.z / 2.0)) / cubeDimentions.z));

				float2 uvs = convertToUVLocation(voxelIndex, int2(3, 3));
				fixed4 col = tex2D(_Layer1, uvs);
				/*fixed4 col;
				col.r = voxelIndex.x;
				col.g = voxelIndex.y;
				col.b = voxelIndex.z;*/
				
				col.a = 1.0;
                return col;
            }
            ENDCG
        }
    }
}
