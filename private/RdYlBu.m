function  map=RdYlBu(m)
%RdYlBu
%# GMT palette RdYlBu.cpt
%# 
%# This product includes color specifications and designs
%# developed by Cynthia Brewer (http://colorbrewer.org/).
%# 
%# Converted to the cpt format by J.J.Green
%# Diverging palette with 11 colours
%# 
%# COLOR_MODEL = RGB

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end

values = [ 
165 000 038
215 048 039
244 109 067
253 174 097
254 224 144
255 255 191
224 243 248
171 217 233
116 173 209
069 117 180
049 054 149]/256;

P = size(values,1);
map = interp1(1:size(values,1), values, linspace(1,P,m), 'linear');
