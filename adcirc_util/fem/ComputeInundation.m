function NewZeta=ComputeInundation(FemGridStruct,Zeta)
% NewZeta=ComputeInundation(FemGridStruct,Zeta)

%mask=NaN*ones(size(FemGridStruct.z));
%mask(FemGridStruct.z<=0)=1;
%NewZeta=(Zeta+FemGridStruct.z).*mask;

NewZeta=(Zeta+FemGridStruct.z);
idx=FemGridStruct.z>=0;
%NewZeta(idx)=Zeta(idx);

NewZeta(idx)=NaN;


