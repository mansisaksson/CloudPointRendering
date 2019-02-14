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

			sampler2D _Layer1;
			sampler2D _Layer2;
			sampler2D _Layer3;
			sampler2D _Layer4;
			sampler2D _Layer5;
			sampler2D _Layer6;
			sampler2D _Layer7;
			sampler2D _Layer8;

			float4 _Layer1_ST;

			static sampler2D Layers[8] = 
			{
				_Layer1,
				_Layer2,
				_Layer3,
				_Layer4,
				_Layer5,
				_Layer6,
				_Layer7,
				_Layer8
			};

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

			struct Box
			{
				float3 Origin;
				float3 Extent;
			};

			struct Line
			{
				float3 Origin;
				float3 Direction;
			};

			fixed4 TraceColorRecursive(Box box, Line ray, int layerIndex, float3 rootBoxDimensions)
			{
				struct Local
				{
					static bool LineTraceBox(Line ray, Box box, inout float3 hitLocation)
					{
						return false;
					}

					static void SplitBoxes(Box box, inout Box boxes[8])
					{
						uint nrOfBoxes = 8;
						uint childPerSide = 2;//round(pow(nrOfBoxes, (1. / 3)));
						float3 bottomRight = box.Origin - box.Extent;
						float3 newBoxExtent = float3(
							box.Extent.x / childPerSide,
							box.Extent.y / childPerSide,
							box.Extent.z / childPerSide
							);

						for (uint i = 0; i < nrOfBoxes; i++)
						{
							uint3 Indices = uint3(
								ceil(i % childPerSide),
								ceil(i / childPerSide),
								ceil((i / childPerSide) % childPerSide)
								); // probs not correct

							float3 newOrigin = float3(
								bottomRight.x + (Indices.x * newBoxExtent.x) + (newBoxExtent.x / 2.0),
								bottomRight.y + (Indices.y * newBoxExtent.y) + (newBoxExtent.y / 2.0),
								bottomRight.z + (Indices.z * newBoxExtent.z) + (newBoxExtent.z / 2.0)
								);
							Box childBox = {
								newOrigin,
								newBoxExtent
							};
							boxes[i] = childBox;
						}
					}
					
					static float2 convertToUVLocation(int3 voxelIndex, int2 textureSize)
					{
						uint oneDimentionalLocation = (voxelIndex.x + voxelIndex.y + voxelIndex.z);
						uint rowCount = textureSize.x;

						uint yLocation = ceil(oneDimentionalLocation / rowCount);
						uint xLocation = ceil(oneDimentionalLocation % rowCount);

						return float2(float(xLocation) / textureSize.x, float(yLocation) / textureSize.y);
					}
				};

				Box ChildBoxes[8];
				Local::SplitBoxes(box, ChildBoxes);

				// Line trace all boxes
				struct BoxTraceResult
				{
					int BoxIndex;
					bool bHit;
					float3 HitLocation;
				};

				BoxTraceResult boxTraceResults[8];
				for (int i = 0; i < 8; i++) {
					float3 hitLocation = float3(0, 0, 0);
					bool bHit = Local::LineTraceBox(ray, ChildBoxes[i], hitLocation);
					BoxTraceResult traceResult = { i, bHit,	hitLocation	};
					boxTraceResults[i] = traceResult;
				}

				//boxTraceResult.SortByHitLocation()

				// Recursive search children for color data
				for (i = 0; i < 8; i++) {
					if (boxTraceResults[i].bHit) {
						fixed4 childColor = TraceColorRecursive(
							ChildBoxes[boxTraceResults[i].BoxIndex], 
							ray, 
							layerIndex + 1, 
							rootBoxDimensions
						);
						if (ceil(childColor.a) == 0) {
							return childColor;
						}
					}
				}

				// Sample texture
				/*float3 boxDimentions = Box.Extent * 2;
				uint3 voxelIndex = int3(
					round((IN.localPos.x + (boxDimentions.x / 2.0)) / rootBoxDimensions.x),
					round((IN.localPos.y + (boxDimentions.y / 2.0)) / rootBoxDimensions.y),
					round((IN.localPos.z + (boxDimentions.z / 2.0)) / rootBoxDimensions.z));

				texture = get_texture(layerIndex)
				uv = convertToUVLocation(voxelIndex, texture.size)
				return tex2D(texture, uvs);*/

				return float4(0, 0, 0, 1);
			}

            fixed4 frag (v2f IN) : COLOR
            {
				float3 BoxExtent = float3(1.0, 1.0, 1.0);
				Box RootBox = { float3(0, 0, 0), BoxExtent };
				Line ray = { IN.screenpos, (IN.screenpos - IN.localPos) };

				float4 color = TraceColorRecursive(RootBox, ray, 0, BoxExtent);
				//float3 cubeDimentions = float3(2.0, 2.0, 2.0);
				//uint3 voxelIndex = int3(
				//	round((IN.localPos.x + (cubeDimentions.x / 2.0)) / cubeDimentions.x),
				//	round((IN.localPos.y + (cubeDimentions.y / 2.0)) / cubeDimentions.y),
				//	round((IN.localPos.z + (cubeDimentions.z / 2.0)) / cubeDimentions.z));

				//float2 uvs = convertToUVLocation(voxelIndex, int2(3, 3));
				//fixed4 col = tex2D(_Layer1, uvs);
				///*fixed4 col;
				//col.r = voxelIndex.x;
				//col.g = voxelIndex.y;
				//col.b = voxelIndex.z;*/
				//
				//col.a = 1.0;
				//return col;

				return float4(0, 0, 0, 1);
            }
            ENDCG
        }
    }
}
