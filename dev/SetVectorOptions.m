function VectorOptions=SetVectorOptions(varargin)
% vector drawing options
%  SetVectorOptions(Stride,ScaleFac,Color)


VectorOptions.Stride=100;
VectorOptions.ScaleFac=50;
VectorOptions.Color='k';


k=1;
while k<length(varargin),
  switch lower(varargin{k}),
    case 'stride',
      VectorOptions.Stride=varargin{k+1};
      varargin([k k+1])=[];
    case 'ScaleFac',
      VectorOptions.ScaleFac=varargin{k+1};
      varargin([k k+1])=[];
    case 'Color',
      VectorOptions.Color=varargin{k+1};
      varargin([k k+1])=[];
    otherwise
      k=k+2;
  end;
end;

