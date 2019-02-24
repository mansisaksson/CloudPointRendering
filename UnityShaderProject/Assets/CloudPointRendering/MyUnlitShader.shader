// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/MyUnlitShader"
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
							newBoxExtent
						};
						boxes[i] = childBox;
					}
				}

				static float2 convertToUVLocation(int3 voxelIndex, uint3 dimensions, uint2 textureSize, uint layerIndex)
				{
					uint layerSizes[7] = {
						0,
						1 * 1 * 1,
						2 * 2 * 2,
						4 * 4 * 4,
						8 * 8 * 8,
						16 * 16 * 16,
						32 * 32 * 32
					};

					uint layerOffsets[7] = {
						0,
						layerSizes[1],
						layerSizes[1] + layerSizes[2],
						layerSizes[1] + layerSizes[2] + layerSizes[3],
						layerSizes[1] + layerSizes[2] + layerSizes[3] + layerSizes[4],
						layerSizes[1] + layerSizes[2] + layerSizes[3] + layerSizes[4] + layerSizes[5],
						layerSizes[1] + layerSizes[2] + layerSizes[3] + layerSizes[4] + layerSizes[5] + layerSizes[6]
					};
					

					// swap z and y axis
					int oneDimentionalLocation =
						voxelIndex.x +
						(voxelIndex.z * dimensions.x) +
						(voxelIndex.y * dimensions.x * dimensions.y) + layerOffsets[layerIndex];

					uint2 texLocation = uint2(
						oneDimentionalLocation % (textureSize.x),
						oneDimentionalLocation / (textureSize.x));

					
					float2 pixelSize = float2(1.0, 1.0) / float2(textureSize);
					float2 halfPixel = pixelSize / 2.0;

					//return (float2(texLocation) / float2(textureSize - uint2(1, 1))) + halfPixel;
					return float2(pixelSize.x * texLocation.x, pixelSize.y * texLocation.y) + halfPixel;
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
				int stackIndex = 0;
				boxStack[0] = box;
				
				[loop] for (int count = 0; count < 100 && stackIndex > -1; count++)
				{
					Box currentBox = boxStack[stackIndex];
					stackIndex--;

					float3 voxelLength = (currentBox.Extent * 2.0);
					float3 voxelLocation = (currentBox.Origin - currentBox.Extent) + rootBoxExtent; // + rootBoxExtent to offset to positive space

					int layerIndex = log2(round(rootBoxLength.x / voxelLength.x));

					uint3 voxelsPerSide = round(rootBoxLength / voxelLength);
					uint3 voxelIndex = round((voxelLocation / rootBoxLength) * voxelsPerSide);

					float2 uv = Helpers::convertToUVLocation(
						voxelIndex,
						voxelsPerSide,
						int2(_OctreeTex_TexelSize.z, _OctreeTex_TexelSize.w),
						layerIndex
					);

					fixed4 currentBoxColor = tex2D(_OctreeTex, uv);

					int bIsValidColor = step(0.001, currentBoxColor.a);
					color = (color * (1 - bIsValidColor)) + (currentBoxColor * bIsValidColor);
					//stackIndex = stackIndex - (1 - bIsValidColor); // -1 if currentBoxColor.a == 0
					
					if (bIsValidColor && layerIndex == 6)
						return color;

					//if (bIsValidColor)
					{
						Box ChildBoxes[8];
						Helpers::SplitBoxes(currentBox, ChildBoxes);

						/*int index = 3;
						if (log2(round(rootBoxLength.x / voxelLength.x)) == 0)
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
							stackIndex = stackIndex + (1 * boxTraceResults[sIndex] * bIsValidColor); // Only increment stack if we hit the box
						}
					}
				}

				return color;
			}

            fixed4 frag (v2f IN) : COLOR
            {
				float3 BoxExtent = float3(1.0, 1.0, 1.0);
				Box RootBox = { float3(0, 0, 0), BoxExtent };
				float3 rayDir = (IN.dir);
				Line ray = { IN.localPos + (rayDir * 100), IN.localPos - (rayDir * 100) };

				return TraceColorRecursive(RootBox, ray);
            }
            ENDCG
        }
    }
}
