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

			sampler2D _Layer0;
			sampler2D _Layer1;
			sampler2D _Layer2;
			sampler2D _Layer3;
			sampler2D _Layer4;
			sampler2D _Layer5;
			sampler2D _Layer6;
			sampler2D _Layer7;

			float4 _Layer0_ST;

			/*
			 x contains 1.0/width
			 y contains 1.0/height
			 z contains width
			 w contains height
			*/
			float4 _Layer0_TexelSize;
			float4 _Layer1_TexelSize;
			float4 _Layer2_TexelSize;
			float4 _Layer3_TexelSize;
			float4 _Layer4_TexelSize;
			float4 _Layer5_TexelSize;
			float4 _Layer6_TexelSize;
			float4 _Layer7_TexelSize;

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

				static int IsLineInBox(Box box, Line ray)
				{
					float3 boxExtent = box.Extent / 2;
					float3 LB1 = ray.L1 - (box.Origin / 2);
					float3 LB2 = ray.L2 - (box.Origin / 2);

					// Get line midpoint and extent
					float3 LMid = (LB1 + LB2) * 0.5f;
					float3 L = (LB1 - LMid);
					float3 LExt = float3(abs(L.x), abs(L.y), abs(L.z));

					// Use Separating Axis Test
					// Separation vector from box center to line center is LMid, since the line is in box space
					return step(abs(LMid.x), boxExtent.x + LExt.x)
						* step(abs(LMid.y), boxExtent.y + LExt.y)
						* step(abs(LMid.z), boxExtent.z + LExt.z)
						
						// Crossproducts of line and each axis
						* step(abs(LMid.y * L.z - LMid.z * L.y), (boxExtent.y * LExt.z + boxExtent.z * LExt.y))
						* step(abs(LMid.x * L.z - LMid.z * L.x), (boxExtent.x * LExt.z + boxExtent.z * LExt.x))
						* step(abs(LMid.x * L.y - LMid.y * L.x), (boxExtent.x * LExt.y + boxExtent.y * LExt.x));
						
					// Use Separating Axis Test
					// Separation vector from box center to line center is LMid, since the line is in box space
					//if (abs(LMid.x) > boxExtent.x + LExt.x) return false;
					//if (abs(LMid.y) > boxExtent.y + LExt.y) return false;
					//if (abs(LMid.z) > boxExtent.z + LExt.z) return false;
					//// Crossproducts of line and each axis
					//if (abs(LMid.y * L.z - LMid.z * L.y) > (boxExtent.y * LExt.z + boxExtent.z * LExt.y)) return false;
					//if (abs(LMid.x * L.z - LMid.z * L.x) > (boxExtent.x * LExt.z + boxExtent.z * LExt.x)) return false;
					//if (abs(LMid.x * L.y - LMid.y * L.x) > (boxExtent.x * LExt.y + boxExtent.y * LExt.x)) return false;
					//// No separating axis, the line intersects
					//return true;
				}
			};

			struct Helpers
			{
				static void SplitBoxes(Box parentBox, inout Box boxes[8])
				{
					float3 newBoxExtent = parentBox.Extent * 0.5;

					static float3 Indices[8] =
					{
						float3(-1, -1, -1),
						float3(-1, -1,  1),
						float3( 1, -1, -1),
						float3( 1, -1,  1),
						float3(-1,  1, -1),
						float3(-1,  1,  1),
						float3( 1,  1, -1),
						float3( 1,  1,  1)
					};
					for (int i = 0; i < 8; i++)
					{
						float3 newOrigin = parentBox.Origin + (Indices[i] * newBoxExtent);
						Box childBox = {
							newOrigin,
							newBoxExtent
						};
						boxes[i] = childBox;
					}
				}

				static float2 convertToUVLocation(int3 voxelIndex, int3 dimensions, int2 textureSize)
				{
					//int3 test[8] = {
					//	int3(0, 0, 0), // 0 + 0 + 0 = 0
					//	int3(1, 0, 0), // 1 + 0 + 0 = 1
					//	int3(0, 1, 0), // 0 + 2 + 0 = 2
					//	int3(1, 1, 0), // 1 + 2 + 0 = 3

					//	int3(0, 0, 1), // 0 + 0 + 4 = 4
					//	int3(1, 0, 1), // 1 + 0 + 4 = 5
					//	int3(0, 1, 1), // 0 + 2 + 4 = 6
					//	int3(1, 1, 1)  // 1 + 2 + 4 = 7
					//};
					
					// swap z and y axis
					int oneDimentionalLocation = 
						voxelIndex.x + 
						(voxelIndex.z * dimensions.x) +
						(voxelIndex.y * dimensions.x * 2);

					int2 texLocation = int2(
						oneDimentionalLocation % (textureSize.x),
						oneDimentionalLocation / (textureSize.x));

					//float xcord = float(texLocation.x) / float(textureSize.x - 1);
					//float ycord = float(texLocation.y) / float(textureSize.x - 1);
					//return float2(xcord, ycord);
					return float2(texLocation) / float2(textureSize - int2(1, 1));
				}
			};

			fixed4 TraceColorRecursive(Box box, Line ray)
			{
				// Setup constants
				int i = 0;
				fixed4 color = fixed4(0, 0, 0, 0);
				float3 rootBoxExtent = box.Extent;
				float3 rootBoxLength = rootBoxExtent * 2.0;

				// Setup stack
				Box boxStack[100]; // TODO: How big should i make the stack?
				uint stackIndex = 0;
				boxStack[0] = box;
				
				[loop] for (int count = 0; count < 20 && stackIndex != -1; count++)
				{
					Box currentBox = boxStack[stackIndex];
					stackIndex--;
					
					float3 voxelLength = (currentBox.Extent * 2.0);
					float3 voxelLocation = (currentBox.Origin - currentBox.Extent) + rootBoxExtent; // + rootBoxExtent to offset to positive space
					
					fixed4 currentBoxColor = fixed4(0.0, 0.0, 0.0, 0.0);
					int layerIndex = log2(round(rootBoxLength.x / voxelLength.x));

					// Sample color of current box
					{
						int3 voxelsPerSide = round(rootBoxLength / voxelLength);
						int3 voxelIndex = round((voxelLocation / rootBoxLength) * voxelsPerSide);

						// TODO: branch is expensive, sample all children instead
						float2 uv = float2(0, 0);
						if (layerIndex == 0) {
							uv = Helpers::convertToUVLocation(voxelIndex, voxelsPerSide, int2(_Layer0_TexelSize.z, _Layer0_TexelSize.w));
							currentBoxColor = tex2D(_Layer0, uv);
						}
						else if (layerIndex == 1) {
							uv = Helpers::convertToUVLocation(voxelIndex, voxelsPerSide, int2(_Layer1_TexelSize.z, _Layer1_TexelSize.w));
							currentBoxColor = tex2D(_Layer1, uv);
							//return fixed4(float3(voxelIndex), 1);
							//return fixed4(uv.x, 0, 0, 1);
							//return fixed4(0, uv.y, 0, 1);
						}
						else if (layerIndex == 2) {
							uv = Helpers::convertToUVLocation(voxelIndex, voxelsPerSide, int2(_Layer2_TexelSize.z, _Layer2_TexelSize.w));
							currentBoxColor = tex2D(_Layer2, uv);
						}
						else if (layerIndex == 3) {
							uv = Helpers::convertToUVLocation(voxelIndex, voxelsPerSide, int2(_Layer3_TexelSize.z, _Layer3_TexelSize.w));
							currentBoxColor = tex2D(_Layer3, uv);
						}
						else if (layerIndex == 4) {
							uv = Helpers::convertToUVLocation(voxelIndex, voxelsPerSide, int2(_Layer4_TexelSize.z, _Layer4_TexelSize.w));
							currentBoxColor = tex2D(_Layer4, uv);
						}
						else if (layerIndex == 5) {
							uv = Helpers::convertToUVLocation(voxelIndex, voxelsPerSide, int2(_Layer5_TexelSize.z, _Layer5_TexelSize.w));
							currentBoxColor = tex2D(_Layer5, uv);
						}
						else if (layerIndex == 6) {
							uv = Helpers::convertToUVLocation(voxelIndex, voxelsPerSide, int2(_Layer6_TexelSize.z, _Layer6_TexelSize.w));
							currentBoxColor = tex2D(_Layer6, uv);
						}
						/*else if (layerIndex == 7) {
							uv = Helpers::convertToUVLocation(voxelIndex, voxelsPerSide, int2(_Layer7_TexelSize.z, _Layer7_TexelSize.w));
							currentBoxColor = tex2D(_Layer7, uv);
						}*/
					}

					int bIsValidColor = step(0.001, currentBoxColor.a);
					color = (color * (1 - bIsValidColor)) + (currentBoxColor * bIsValidColor);
					stackIndex = stackIndex - (1 - bIsValidColor); // -1 if currentBoxColor.a == 0

					if (bIsValidColor)
					{
						color = currentBoxColor;

						Box ChildBoxes[8];
						Helpers::SplitBoxes(currentBox, ChildBoxes);

						/*int index = 3;
						if (layerIndex == 0)
							return Math::IsLineInBox(ChildBoxes[index], ray) ? fixed4(1, 1, 1, 1) : fixed4(0, 0, 0, 1);*/

						// Collect distances to boxes
						float distances[8] = {
							length(ChildBoxes[0].Origin - ray.L1),
							length(ChildBoxes[1].Origin - ray.L1),
							length(ChildBoxes[2].Origin - ray.L1),
							length(ChildBoxes[3].Origin - ray.L1),
							length(ChildBoxes[4].Origin - ray.L1),
							length(ChildBoxes[5].Origin - ray.L1),
							length(ChildBoxes[6].Origin - ray.L1),
							length(ChildBoxes[7].Origin - ray.L1)
						};

						// Create sorted index list
						int sortedIndices[8] = { 0, 1, 2, 3, 4, 5, 6, 7 };
						for (i = 0; i < 7; i++) {
							for (int j = i + 1; j < 8; j++) {
								int isBigger = step(distances[i], distances[j]);

								float tmp = distances[i];
								distances[i] = (distances[i] * (1 - isBigger)) + (distances[j] * isBigger);
								distances[j] = (distances[j] * (1 - isBigger)) + (tmp * isBigger);

								int iTmp = sortedIndices[i];
								sortedIndices[i] = (sortedIndices[i] * (1 - isBigger)) + (sortedIndices[j] * isBigger);
								sortedIndices[j] = (sortedIndices[j] * (1 - isBigger)) + (iTmp * isBigger);
							}
						}

						// Trace against boxes
						int boxTraceResults[8];
						for (i = 0; i < 8; i++) {
							int sIndex = sortedIndices[i];
							boxTraceResults[sIndex] = Math::IsLineInBox(ChildBoxes[sIndex], ray);
						}

						// Push children to stack
						for (i = 0; i < 8; i++) {
							int sIndex = sortedIndices[i];
							boxStack[stackIndex + 1] = ChildBoxes[sIndex];
							stackIndex = stackIndex + (1 * boxTraceResults[sIndex]); // Only increment stack if we hit the box
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

				/*Box childBoxes[8];
				Helpers::SplitBoxes(RootBox, childBoxes);

				//Helpers::SplitBoxes(childBoxes[4], childBoxes);

				for (int i = 0; i < 8; i++)
				{
					if (Math::IsLineInBox(childBoxes[i], ray))
					{
						static fixed4 colors[8] = {
							fixed4(0, 0, 0, 1),
							fixed4(1, 0, 0, 1),
							fixed4(0, 1, 0, 1),
							fixed4(0, 0, 1, 1),
							fixed4(1, 0, 1, 1),
							fixed4(0, 1, 1, 1),
							fixed4(1, 1, 0, 1),
							fixed4(1, 1, 1, 1)
						};
						return colors[i];
					}
				}*/
				//return Helpers::convertToUVLocation()

				fixed4 color = TraceColorRecursive(RootBox, ray);
				//return IN.pixelCameraPos;
				return color;
            }
            ENDCG
        }
    }
}
