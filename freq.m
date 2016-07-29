function res = freq(x)
	L=length(x);	 	 
	NFFT=256;	 	 
	X=fft(x,NFFT);	 	 
	Px=X.*conj(X)/(NFFT*L); %Power of each freq components	 	 
	res = Px(1:NFFT/2);

end