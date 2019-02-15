// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'

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

			/*
			 x contains 1.0/width
			 y contains 1.0/height
			 z contains width
			 w contains height
			*/
			float4 _Layer1_TexelSize;
			float4 _Layer2_TexelSize;
			float4 _Layer3_TexelSize;
			float4 _Layer4_TexelSize;
			float4 _Layer5_TexelSize;
			float4 _Layer6_TexelSize;
			float4 _Layer7_TexelSize;
			float4 _Layer8_TexelSize;

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
				float3 localPos : POSITION1;
				float3 pixelLocalPos : POSITION2;
			};

			v2f vert(appdata IN)
			{
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color;

				// TODO: Taking camera origin, should probably offset with pixel location
				float4 pixelPos = float4(0, 0, 0, 1);
				//float4 pixelPos = mul(unity_ObjectToWorld, OUT.vertex);
				//pixelPos = mul(unity_WorldToCamera, pixelPos);
				pixelPos.z = 0;
				pixelPos = mul(unity_CameraToWorld, pixelPos);
				pixelPos = mul(unity_WorldToObject, pixelPos);

				OUT.pixelLocalPos = pixelPos.xyz;
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
				float3 L1;
				float3 L2;
			};

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

				static bool IsLineInBox(Box box, Line ray)
				{
					float3 boxExtent = box.Extent / 2;
					float3 LB1 = box.Origin - ray.L1;
					float3 LB2 = box.Origin - ray.L2;

					// Get line midpoint and extent
					float3 LMid = (LB1 + LB2) * 0.5f;
					float3 L = (LB1 - LMid);
					float3 LExt = float3(abs(L.x), abs(L.y), abs(L.z));

					// Use Separating Axis Test
					// Separation vector from box center to line center is LMid, since the line is in box space
					if (abs(LMid.x) > boxExtent.x + LExt.x) return false;
					if (abs(LMid.y) > boxExtent.y + LExt.y) return false;
					if (abs(LMid.z) > boxExtent.z + LExt.z) return false;
					// Crossproducts of line and each axis
					if (abs(LMid.y * L.z - LMid.z * L.y) > (boxExtent.y * LExt.z + boxExtent.z * LExt.y)) return false;
					if (abs(LMid.x * L.z - LMid.z * L.x) > (boxExtent.x * LExt.z + boxExtent.z * LExt.x)) return false;
					if (abs(LMid.x * L.y - LMid.y * L.x) > (boxExtent.x * LExt.y + boxExtent.y * LExt.x)) return false;
					// No separating axis, the line intersects
					return true;
				}
			};

			struct Helpers
			{
				static void SplitBoxes(Box parentBox, float3 rootBoxExtent, inout Box boxes[8])
				{
					float3 newBoxExtent = parentBox.Extent * 0.5;

					static uint3 Indices[8] =
					{
						uint3(0, 0, 0),
						uint3(1, 0, 0),
						uint3(0, 0, 1),
						uint3(1, 0, 1),
						uint3(0, 1, 0),
						uint3(1, 1, 0),
						uint3(0, 1, 1),
						uint3(1, 1, 1)
					};
					for (int i = 0; i < 8; i++)
					{
						float3 newOrigin = parentBox.Origin + (Indices[i] * newBoxExtent) - (newBoxExtent * 0.5);
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

			fixed4 TraceColorRecursive(Box box, Line ray, float3 rootBoxExtent)
			{
				Box boxStack[8 * 8]; // 8 layers * 8 cubes per layer
				uint stackIndex = 0;
				
				boxStack[0] = box;

				int i = 0;
				int count = 0;
				fixed4 color = fixed4(0, 0, 0, 1.0);
				[loop] while (stackIndex != -1)
				{
					count++;
					if (count > 20) {
						return color;
					}

					// Pop a vertex from stack and print it 
					Box currentBox = boxStack[stackIndex];
					stackIndex--;

					// Sample color of current box
					{
						uint layerIndex = ceil((stackIndex + 1) / 8);
						uint3 childrenPerSide = layerIndex * 2;
						uint3 voxelIndex = int3(
							round((currentBox.Origin.x + rootBoxExtent.x) / childrenPerSide.x),
							round((currentBox.Origin.y + rootBoxExtent.y) / childrenPerSide.y),
							round((currentBox.Origin.z + rootBoxExtent.z) / childrenPerSide.z));

						fixed4 currentBoxColor = fixed4(0.0, 0.0, 0.0, 0.0);
						float2 uv = float2(0, 0);
						switch (layerIndex) // stackIndex == layer depth
						{
						case 0:
							uv = Helpers::convertToUVLocation(voxelIndex, int2(_Layer1_TexelSize.z, _Layer1_TexelSize.w));
							currentBoxColor = tex2D(_Layer1, uv);
							break;
						case 1:
							uv = Helpers::convertToUVLocation(voxelIndex, int2(_Layer2_TexelSize.z, _Layer2_TexelSize.w));
							currentBoxColor = tex2D(_Layer2, uv);
							break;
						case 2:
							uv = Helpers::convertToUVLocation(voxelIndex, int2(_Layer3_TexelSize.z, _Layer3_TexelSize.w));
							currentBoxColor = tex2D(_Layer3, uv);
							break;
						case 3:
							uv = Helpers::convertToUVLocation(voxelIndex, int2(_Layer4_TexelSize.z, _Layer4_TexelSize.w));
							currentBoxColor = tex2D(_Layer4, uv);
							break;
						case 4:
							uv = Helpers::convertToUVLocation(voxelIndex, int2(_Layer5_TexelSize.z, _Layer5_TexelSize.w));
							currentBoxColor = tex2D(_Layer5, uv);
							break;
						case 5:
							uv = Helpers::convertToUVLocation(voxelIndex, int2(_Layer6_TexelSize.z, _Layer6_TexelSize.w));
							currentBoxColor = tex2D(_Layer6, uv);
							break;
						case 6:
							uv = Helpers::convertToUVLocation(voxelIndex, int2(_Layer7_TexelSize.z, _Layer7_TexelSize.w));
							currentBoxColor = tex2D(_Layer7, uv);
							break;
						case 7:
							uv = Helpers::convertToUVLocation(voxelIndex, int2(_Layer8_TexelSize.z, _Layer8_TexelSize.w));
							currentBoxColor = tex2D(_Layer8, uv);
							break;
						default:
							break;
						}

						if (currentBoxColor.a != 0.0) {
							color = currentBoxColor;
						}

						else if (currentBoxColor.a == 0.0) {
							stackIndex--;
							continue;
						}
					}

					Box ChildBoxes[8];
					Helpers::SplitBoxes(currentBox, rootBoxExtent, ChildBoxes);

					//int index = 0;
					//return boxTraceResults[index].bHit ? fixed4(abs(boxTraceResults[index].HitLocation), 1.0) : fixed4(0, 0, 0, 1);

					//if (ceil((stackIndex + 1) / 8) == 2)
					//	return Math::IsLineInBox(ChildBoxes[index], ray) ? fixed4(1, 1, 1, 1) : fixed4(0, 0, 0, 1);

					// Collect distances to boxes
					float distances[8] = {
						length(ray.L1 - ChildBoxes[0].Origin),
						length(ray.L1 - ChildBoxes[1].Origin),
						length(ray.L1 - ChildBoxes[2].Origin),
						length(ray.L1 - ChildBoxes[3].Origin),
						length(ray.L1 - ChildBoxes[4].Origin),
						length(ray.L1 - ChildBoxes[5].Origin),
						length(ray.L1 - ChildBoxes[6].Origin),
						length(ray.L1 - ChildBoxes[7].Origin)
					};

					// Create sorted index list
					int sortedIndices[8] = { 0, 1, 2, 3, 4, 5, 6, 7 };
					//for (i = 0; i < 8; i++) { // Easier to find biggest, therefore put in end of array
					//	for (int j = i; j < 8; j++) {
					//		int isBigger = step(distances[i], distances[j]);

					//		float tmp = distances[i];
					//		distances[i] = (distances[i] * (1 - isBigger)) + (distances[j] * isBigger);
					//		distances[j] = (distances[j] * (1 - isBigger)) + (tmp * isBigger);

					//		sortedIndices[i] = (sortedIndices[i] * (1 - isBigger)) + (j * isBigger);
					//	}
					//}

					// Trace against boxes
					bool boxTraceResults[8];
					for (i = 0; i < 8; i++) {
						int sIndex = sortedIndices[i];
						boxTraceResults[sIndex] = Math::IsLineInBox(ChildBoxes[sIndex], ray);
					}

					// Push children to stack
					for (i = 0; i < 8; i++) {
						int sIndex = sortedIndices[i];
						if (boxTraceResults[sIndex]) {
							stackIndex++;
							boxStack[stackIndex] = ChildBoxes[sIndex];
						}
					}
				}

				return color;
			}

            fixed4 frag (v2f IN) : COLOR
            {
				float3 BoxExtent = float3(1.0, 1.0, 1.0);
				Box RootBox = { float3(0, 0, 0), BoxExtent };
				float3 rayDir = normalize(IN.localPos - IN.pixelLocalPos);

				Line ray = { IN.pixelLocalPos, IN.pixelLocalPos + (rayDir * 100) };

				fixed4 color = TraceColorRecursive(RootBox, ray, BoxExtent);
				//return IN.pixelCameraPos;
				return color;
            }
            ENDCG
        }
    }
}
