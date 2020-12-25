#ifndef SIMPLE_IBL_INCLUDED
#define SIMPLE_IBL_INCLUDED

half2 CalculateUV(half2 uv, half frame)
{
    half tile = 4;
	//求行
	float row = floor(frame/tile);
	//求列
	float column = frame - row*_Row;
	half2 uv  = i.uv +half2(column,-row);
	//列
	uv.x/=tile;
	//行 row/_Row = 起始行uv i.uv.y/_Row = i.uv.y缩放  相加 = 当前uv.y
	uv.y/=tile;
	return tex2D(_MainTex,uv);
}

#endif