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
				float3 P1;
				float3 P2;
			};

			struct Line
			{
				float3 P1;
				float3 P2;
			};

			fixed4 TraceColorRecursive(Box box, Line ray, int layerIndex, float3 rootBoxDimensions)
			{
				struct Math
				{
					static int GetIntersection(float fDst1, float fDst2, float3 P1, float3 P2, inout float3 Hit)
					{
						if ((fDst1 * fDst2) >= 0.0f) return 0;
						if (fDst1 == fDst2) return 0;
						Hit = P1 + (P2 - P1) * (-fDst1 / (fDst2 - fDst1));
						return 1;
					}

					static int InBox(float3 Hit, float3 B1, float3 B2, const int Axis)
					{
						if (Axis == 1 && Hit.z > B1.z && Hit.z < B2.z && Hit.y > B1.y && Hit.y < B2.y) return 1;
						if (Axis == 2 && Hit.z > B1.z && Hit.z < B2.z && Hit.x > B1.x && Hit.x < B2.x) return 1;
						if (Axis == 3 && Hit.x > B1.x && Hit.x < B2.x && Hit.y > B1.y && Hit.y < B2.y) return 1;
						return 0;
					}

					// returns true if line (L1, L2) intersects with the box (B1, B2)
					// returns intersection point in Hit
					static bool CheckLineBox(float3 B1, float3 B2, float3 L1, float3 L2, inout float3 Hit)
					{
						if (L2.x < B1.x && L1.x < B1.x) return false;
						if (L2.x > B2.x && L1.x > B2.x) return false;
						if (L2.y < B1.y && L1.y < B1.y) return false;
						if (L2.y > B2.y && L1.y > B2.y) return false;
						if (L2.z < B1.z && L1.z < B1.z) return false;
						if (L2.z > B2.z && L1.z > B2.z) return false;
						if (L1.x > B1.x && L1.x < B2.x &&
							L1.y > B1.y && L1.y < B2.y &&
							L1.z > B1.z && L1.z < B2.z)
						{
							Hit = L1;
							return true;
						}
						if ((GetIntersection(L1.x - B1.x, L2.x - B1.x, L1, L2, Hit) && InBox(Hit, B1, B2, 1))
							|| (GetIntersection(L1.y - B1.y, L2.y - B1.y, L1, L2, Hit) && InBox(Hit, B1, B2, 2))
							|| (GetIntersection(L1.z - B1.z, L2.z - B1.z, L1, L2, Hit) && InBox(Hit, B1, B2, 3))
							|| (GetIntersection(L1.x - B2.x, L2.x - B2.x, L1, L2, Hit) && InBox(Hit, B1, B2, 1))
							|| (GetIntersection(L1.y - B2.y, L2.y - B2.y, L1, L2, Hit) && InBox(Hit, B1, B2, 2))
							|| (GetIntersection(L1.z - B2.z, L2.z - B2.z, L1, L2, Hit) && InBox(Hit, B1, B2, 3)))
							return true;

						return false;
					}
				};

				struct Local
				{
					static bool LineTraceBox(Line ray, Box box, inout float3 hitLocation)
					{
						return Math::CheckLineBox(box.P1, box.P2, ray.P1, ray.P2, hitLocation);
					}

					static void SplitBoxes(Box box, inout Box boxes[8])
					{
						uint nrOfBoxes = 8;
						uint childPerSide = 2;//round(pow(nrOfBoxes, (1. / 3)));
						float3 bottomRight = box.P2;
						float3 newBoxExtent = (box.P2 - box.P1) / 2.0;

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

				struct BoxStack
				{
					Box BoxStack[800];
					int stackIndex;

					void Push(Box box)
					{

					}

					Box Pop()
					{
						Box box = { float3(0, 0, 0), float3(0, 0, 0) };
						return box;
					}

					bool IsEmpty()
					{
						return stackIndex == -1;
					}
				};

				BoxStack boxStack;
				boxStack.Push(box);

				fixed4 color;
				while (!boxStack.IsEmpty())
				{
					// Pop a vertex from stack and print it 
					box = boxStack.Pop();

					// Get box color
					// if (has no color)
					//		continue

					// Sample texture
					/*float3 boxDimentions = Box.Extent * 2;
					uint3 voxelIndex = int3(
						round((IN.localPos.x + (boxDimentions.x / 2.0)) / rootBoxDimensions.x),
						round((IN.localPos.y + (boxDimentions.y / 2.0)) / rootBoxDimensions.y),
						round((IN.localPos.z + (boxDimentions.z / 2.0)) / rootBoxDimensions.z));

					texture = get_texture(layerIndex)
					uv = convertToUVLocation(voxelIndex, texture.size)
					return tex2D(texture, uvs);*/

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
						BoxTraceResult traceResult = { i, bHit,	hitLocation };
						boxTraceResults[i] = traceResult;
					}

					//boxTraceResult.ReverseSortByHitLocation()

					// Depth first search children for color data
					for (i = 0; i < 8; i++) {
						if (boxTraceResults[i].bHit) {
							boxStack.Push(ChildBoxes[boxTraceResults[i].BoxIndex]);
						}
					}
				}

				return float4(0, 0, 0, 1);
			}

            fixed4 frag (v2f IN) : COLOR
            {
				float3 BoxExtent = float3(1.0, 1.0, 1.0);
				Box RootBox = { -BoxExtent, BoxExtent };
				float3 rayDir = (IN.screenpos - IN.localPos);
				Line ray = { IN.screenpos, IN.screenpos + rayDir * 200 };

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

				return color;
            }
            ENDCG
        }
    }
}
