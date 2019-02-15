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

				float4 pixelPos = mul(unity_ObjectToWorld, OUT.vertex);
				pixelPos = mul(unity_WorldToCamera, pixelPos);
				pixelPos.z = 0;
				pixelPos = mul(unity_CameraToWorld, pixelPos);
				pixelPos = mul(unity_WorldToObject, pixelPos);

				OUT.pixelLocalPos = pixelPos.xyz;
				OUT.localPos = IN.vertex.xyz;

				return OUT;
			}

			struct Box
			{
				float3 Min;
				float3 Max;
			};

			struct Line
			{
				float3 P1;
				float3 P2;
			};

			fixed4 TraceColorRecursive(Box box, Line ray, float3 rootBoxExtent)
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

					//bool CBBox::IsLineInBox(const CVec3& L1, const CVec3& L2)
					//{
					//	// Put line in box space
					//	CMatrix MInv = m_M.InvertSimple();
					//	CVec3 LB1 = MInv * L1;
					//	CVec3 LB2 = MInv * L2;

					//	// Get line midpoint and extent
					//	CVec3 LMid = (LB1 + LB2) * 0.5f;
					//	CVec3 L = (LB1 - LMid);
					//	CVec3 LExt = CVec3(fabs(L.x), fabs(L.y), fabs(L.z));

					//	// Use Separating Axis Test
					//	// Separation vector from box center to line center is LMid, since the line is in box space
					//	if (fabs(LMid.x) > m_Extent.x + LExt.x) return false;
					//	if (fabs(LMid.y) > m_Extent.y + LExt.y) return false;
					//	if (fabs(LMid.z) > m_Extent.z + LExt.z) return false;
					//	// Crossproducts of line and each axis
					//	if (fabs(LMid.y * L.z - LMid.z * L.y) > (m_Extent.y * LExt.z + m_Extent.z * LExt.y)) return false;
					//	if (fabs(LMid.x * L.z - LMid.z * L.x) > (m_Extent.x * LExt.z + m_Extent.z * LExt.x)) return false;
					//	if (fabs(LMid.x * L.y - LMid.y * L.x) > (m_Extent.x * LExt.y + m_Extent.y * LExt.x)) return false;
					//	// No separating axis, the line intersects
					//	return true;
					//}

					static bool IsLineInBox(float3 B1, float3 B2, float3 L1, float3 L2)
					{
						float3 BoxExtent = (B2 - B1) / 2.0;
						float3 BoxOrigin = B2 - BoxExtent;

						float3 LB1 = L1 - BoxOrigin;
						float3 LB2 = L2 - BoxOrigin;

						// Get line midpoint and extent
						float3 LMid = (LB1 + LB2) * 0.5f;
						float3 L = (LB1 - LMid);
						float3 LExt = float3(abs(L.x), abs(L.y), abs(L.z));

						// Use Separating Axis Test
						// Separation vector from box center to line center is LMid, since the line is in box space
						if (abs(LMid.x) > BoxExtent.x + LExt.x) return false;
						if (abs(LMid.y) > BoxExtent.y + LExt.y) return false;
						if (abs(LMid.z) > BoxExtent.z + LExt.z) return false;
						// Crossproducts of line and each axis
						if (abs(LMid.y * L.z - LMid.z * L.y) > (BoxExtent.y * LExt.z + BoxExtent.z * LExt.y)) return false;
						if (abs(LMid.x * L.z - LMid.z * L.x) > (BoxExtent.x * LExt.z + BoxExtent.z * LExt.x)) return false;
						if (abs(LMid.x * L.y - LMid.y * L.x) > (BoxExtent.x * LExt.y + BoxExtent.y * LExt.x)) return false;
						// No separating axis, the line intersects
						return true;
					}
				};

				struct Local
				{
					static void SplitBoxes(Box box, inout Box boxes[8])
					{
						float3 parentBoxSize = abs(box.Max - box.Min);
						float3 newBoxSize = parentBoxSize / 2.0;

						static uint3 Indices[8] =
						{
							uint3(0, 0, 0),
							uint3(1, 0, 0),
							uint3(0, 1, 0),
							uint3(1, 1, 0),
							uint3(0, 0, 1),
							uint3(1, 0, 1),
							uint3(0, 1, 1),
							uint3(1, 1, 1)
						};
						for (uint i = 0; i < 8; i++)
						{
							float3 newMin = float3(
								box.Min.x + round(Indices[i].x * newBoxSize.x),
								box.Min.y + round(Indices[i].y * newBoxSize.y),
								box.Min.z + round(Indices[i].z * newBoxSize.z)
								);
							Box childBox = {
								newMin,
								newMin + newBoxSize
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

				Box boxStack[8 * 8]; // 8 layers * 8 cubes per layer
				uint stackIndex = 0;
				
				boxStack[0] = box;

				int count = 0;
				fixed4 color = fixed4(0, 0, 0, 1.0);
				[loop] while (stackIndex != -1)
				{
					count++;
					if (count > 50) {
						return color;
					}
					// Pop a vertex from stack and print it 
					box = boxStack[stackIndex];

					// Sample color of current box
					{
						float3 boxDimentions = abs(box.Min - box.Max);
						float3 boxPos = box.Min + (boxDimentions / 2.0);
						uint3 voxelIndex = int3(
							round((boxPos.x - rootBoxExtent.x) / rootBoxExtent.x),
							round((boxPos.y - rootBoxExtent.y) / rootBoxExtent.y),
							round((boxPos.z - rootBoxExtent.z) / rootBoxExtent.z));

						fixed4 currentBoxColor = fixed4(0.0, 0.0, 0.0, 0.0);
						float2 uv = float2(0, 0);
						uint layerIndex = ceil(stackIndex / 8);
						switch (layerIndex) // stackIndex == layer depth
						{
						case 0:
							uv = Local::convertToUVLocation(voxelIndex, int2(_Layer1_TexelSize.z, _Layer1_TexelSize.w));
							currentBoxColor = fixed4(float(stackIndex), 0, 0, 1);//tex2D(_Layer1, uv);
							break;
						case 1:
							uv = Local::convertToUVLocation(voxelIndex, int2(_Layer2_TexelSize.z, _Layer2_TexelSize.w));
							currentBoxColor = tex2D(_Layer2, uv);
							break;
						case 2:
							uv = Local::convertToUVLocation(voxelIndex, int2(_Layer3_TexelSize.z, _Layer3_TexelSize.w));
							currentBoxColor = tex2D(_Layer3, uv);
							break;
						case 3:
							uv = Local::convertToUVLocation(voxelIndex, int2(_Layer4_TexelSize.z, _Layer4_TexelSize.w));
							currentBoxColor = tex2D(_Layer4, uv);
							break;
						case 4:
							uv = Local::convertToUVLocation(voxelIndex, int2(_Layer5_TexelSize.z, _Layer5_TexelSize.w));
							currentBoxColor = tex2D(_Layer5, uv);
							break;
						case 5:
							uv = Local::convertToUVLocation(voxelIndex, int2(_Layer6_TexelSize.z, _Layer6_TexelSize.w));
							currentBoxColor = tex2D(_Layer6, uv);
							break;
						case 6:
							uv = Local::convertToUVLocation(voxelIndex, int2(_Layer7_TexelSize.z, _Layer7_TexelSize.w));
							currentBoxColor = tex2D(_Layer7, uv);
							break;
						case 7:
							uv = Local::convertToUVLocation(voxelIndex, int2(_Layer8_TexelSize.z, _Layer8_TexelSize.w));
							currentBoxColor = tex2D(_Layer8, uv);
							break;
						default:
							break;
						}

						if (currentBoxColor.a != 0.0) {
							color = currentBoxColor;
						}

						if (currentBoxColor.a == 0.0) {
							stackIndex--;
							continue;
						}
					}

					Box ChildBoxes[8];
					Local::SplitBoxes(box, ChildBoxes);

					// Line trace all boxes
					struct BoxTraceResult
					{
						int BoxIndex;
						bool bHit;
						float3 HitLocation;
					};

					//return Math::IsLineInBox(ChildBoxes[0].Min, ChildBoxes[0].Max, ray.P1, ray.P2) ? fixed4(1, 1, 1, 1) : fixed4(0, 0, 0, 1);

					BoxTraceResult boxTraceResults[8];
					for (int i = 0; i < 8; i++) {
						float3 hitLocation = float3(0, 0, 0);
						bool bHit = Math::CheckLineBox(ChildBoxes[i].Min, ChildBoxes[i].Max, ray.P1, ray.P2, hitLocation);
						BoxTraceResult traceResult = { i, bHit,	hitLocation };
						boxTraceResults[i] = traceResult;
					}

					//Box childBox = ChildBoxes[boxTraceResults[0].BoxIndex];
					//return fixed4(childBox.Min, 1.0);
					//return boxTraceResults[0].bHit ? fixed4(abs(boxTraceResults[0].HitLocation), 1.0) : fixed4(0, 0, 0, 1);

					//boxTraceResult.ReverseSortByHitLocation()

					// Depth first search children for color data
					for (i = 0; i < 8; i++) {
						if (boxTraceResults[i].bHit) {
							stackIndex++;
							boxStack[stackIndex] = ChildBoxes[boxTraceResults[i].BoxIndex];
						}
					}
				}

				return color;
			}

            fixed4 frag (v2f IN) : COLOR
            {
				float3 BoxExtent = float3(1.0, 1.0, 1.0);
				Box RootBox = { -BoxExtent, BoxExtent };
				float3 rayDir = (IN.localPos - IN.pixelLocalPos);

				Line ray = { IN.pixelLocalPos, IN.pixelLocalPos + (rayDir * 100) }; // TODO: Don't think this is correct

				fixed4 color = TraceColorRecursive(RootBox, ray, BoxExtent);
				//return IN.pixelCameraPos;
				return color;
            }
            ENDCG
        }
    }
}
