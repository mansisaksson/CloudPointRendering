Shader "Unlit/Multi-Sample"
{
	Properties
	{
		_OctreeTex("_OctreeTex", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		//ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _OctreeTex;

			/*
			 x contains 1.0/width
			 y contains 1.0/height
			 z contains width
			 w contains height
			*/
			float4 _OctreeTex_TexelSize;

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
				float3 localPos : POSITION1;
				float3 dir : POSITION3;
			};

			v2f vert(appdata IN)
			{
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.color = IN.color;

				OUT.localPos = IN.vertex.xyz;
				OUT.dir = ObjSpaceViewDir(IN.vertex);

				return OUT;
			}

			struct Box
			{
				float3 Origin;
				float3 Extent;
				fixed4 Color;
				uint LayerIndex;
			};

			struct Line
			{
				float3 L1;
				float3 L2;
			};

			struct Math
			{
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
						float3( 1, -1, -1),
						float3(-1, -1,  1),
						float3( 1, -1,  1),
						float3(-1,  1, -1),
						float3( 1,  1, -1),
						float3(-1,  1,  1),
						float3( 1,  1,  1)
					};
					for (int i = 0; i < 8; i++)
					{
						float3 newOrigin = parentBox.Origin + (Indices[i] * newBoxExtent);
						Box childBox = {
							newOrigin,
							newBoxExtent,
							fixed4(0, 0, 0, 0),
							parentBox.LayerIndex + 1
						};
						boxes[i] = childBox;
					}
				}

				static float2 convertToUVLocation(int3 voxelIndex, uint3 dimensions, uint2 textureSize, uint layerIndex)
				{
					static uint layerSizes[8] = {
						0,
						1 * 1 * 1,
						2 * 2 * 2,
						4 * 4 * 4,
						8 * 8 * 8,
						16 * 16 * 16,
						32 * 32 * 32,
						64 * 64 * 64,
					};

					static uint layerOffsets[8] = {
						0,
						layerSizes[1],
						layerSizes[1] + layerSizes[2],
						layerSizes[1] + layerSizes[2] + layerSizes[3],
						layerSizes[1] + layerSizes[2] + layerSizes[3] + layerSizes[4],
						layerSizes[1] + layerSizes[2] + layerSizes[3] + layerSizes[4] + layerSizes[5],
						layerSizes[1] + layerSizes[2] + layerSizes[3] + layerSizes[4] + layerSizes[5] + layerSizes[6],
						layerSizes[1] + layerSizes[2] + layerSizes[3] + layerSizes[4] + layerSizes[5] + layerSizes[6] + layerSizes[7],
					};
					
					int oneDimentionalLocation =
						voxelIndex.x +
						(voxelIndex.z * dimensions.x) +
						(voxelIndex.y * dimensions.x * dimensions.y) + layerOffsets[layerIndex];

					uint2 texLocation = uint2(
						oneDimentionalLocation % (textureSize.x),
						oneDimentionalLocation / (textureSize.x));
					
					float2 pixelSize = float2(1.0, 1.0) / float2(textureSize);
					float2 halfPixel = pixelSize / 2.0;
					return pixelSize * texLocation + halfPixel;
				}

				static void FillChildColors(inout Box ChildBoxes[8], Box RootBox, Line ray)
				{
					float3 rootBoxExtent = RootBox.Extent;
					float3 rootBoxLength = rootBoxExtent * 2.0;

					[unroll] for (int i = 0; i < 8; i++)
					{
						Box childBox = ChildBoxes[i];

						float3 voxelLength = (childBox.Extent * 2.0);
						float3 voxelLocation = (childBox.Origin - childBox.Extent) + rootBoxExtent; // + rootBoxExtent to offset to positive space

						int layerIndex = log2(round(rootBoxLength.x / voxelLength.x));

						uint3 voxelsPerSide = round(rootBoxLength / voxelLength);
						uint3 voxelIndex = round((voxelLocation / rootBoxLength) * voxelsPerSide);

						float2 uv = Helpers::convertToUVLocation(
							voxelIndex,
							voxelsPerSide,
							int2(_OctreeTex_TexelSize.z, _OctreeTex_TexelSize.w),
							layerIndex
						);

						int bHitBox = Math::IsLineInBox(childBox, ray); // Trace against boxes
						childBox.Color = tex2D(_OctreeTex, uv) * bHitBox; // If we didn't hit the box, treat is having no color
						ChildBoxes[i] = childBox;
					}
				}

				static void SortByDistance(float distances[8], inout int sortedIndices[8])
				{
					// Create sorted index list
					[unroll] for (int i = 0; i < 7; i++) {
						[unroll] for (int j = i + 1; j < 8; j++) {
							int isBigger = step(distances[i], distances[j]);

							float tmp = distances[i];
							distances[i] = (distances[i] * (1 - isBigger)) + (distances[j] * isBigger);
							distances[j] = (distances[j] * (1 - isBigger)) + (tmp * isBigger);

							int iTmp = sortedIndices[i];
							sortedIndices[i] = (sortedIndices[i] * (1 - isBigger)) + (sortedIndices[j] * isBigger);
							sortedIndices[j] = (sortedIndices[j] * (1 - isBigger)) + (iTmp * isBigger);
						}
					}
				}
			};

			fixed4 TraceColorRecursive(Box box, Line ray)
			{
				// Setup constants
				int i = 0;
				fixed4 bestBoxColor = box.Color;
				int bestBoxLayerIndex = box.LayerIndex;

				
				// Setup stack
				Box boxStack[50]; // TODO: How big should i make the stack?
				int stackIndex = 0;
				boxStack[0] = box;
				
				[loop] for (int count = 0; count < 30; count++)
				{
					Box currentBox = boxStack[stackIndex];
					stackIndex = clamp(stackIndex - 1, 0, 9999);

					int bIsBetterBox = step(bestBoxLayerIndex, currentBox.LayerIndex); // -1 since equals return true and we want bigger

					bestBoxColor = (bestBoxColor * (1 - bIsBetterBox)) + (currentBox.Color * bIsBetterBox);
					bestBoxLayerIndex = (bestBoxLayerIndex * (1 - bIsBetterBox)) + (currentBox.LayerIndex * bIsBetterBox);

					if (bestBoxLayerIndex == 7)
						return currentBox.Color;

					Box ChildBoxes[8];
					Helpers::SplitBoxes(currentBox, ChildBoxes);
					Helpers::FillChildColors(ChildBoxes, box, ray);

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
					int sortedIndices[8] = { 0, 1, 2, 3, 4, 5, 6, 7 };
					Helpers::SortByDistance(distances, sortedIndices);

					[unroll] for (i = 0; i < 8; i++) 
					{
						int sIndex = sortedIndices[i];
						Box childBox = ChildBoxes[sIndex];

						int bIsValidColor = step(0.001, childBox.Color.a);
						boxStack[stackIndex + 1] = childBox;
						stackIndex = stackIndex + (1 * bIsValidColor); // Only increment stack if we hit a box with valid color
					}
				}

				return bestBoxColor;
			}

            fixed4 frag (v2f IN) : COLOR
            {
				float3 BoxExtent = float3(1.0, 1.0, 1.0);
				Box RootBox = { float3(0, 0, 0), BoxExtent, fixed4(1, 1, 1, 1), 0 };
				float3 rayDir = (IN.dir);
				Line ray = { IN.localPos + (rayDir * 100), IN.localPos - (rayDir * 100) };

				fixed4 color = TraceColorRecursive(RootBox, ray);
				return fixed4(color.r, 0, 0, color.a);
            }
            ENDCG
        }
    }
}
