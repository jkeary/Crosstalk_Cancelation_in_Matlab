% Name: James Keary 
% Student ID: N12432851 
% NetID: jpk349 
% Due Date: 4/27/2012
% Assignment: Crosstalk Cancellation Implementation in Stereo pair
% 
% FUNCTION DESCRIPTION
%
% XTalker
%   function takes 2 channels of 3d surround audio and removes deleterious
%   crosstalk signal.  KEMAR HRTF impulse responses from 
%   http://sound.media.mit.edu/resources/KEMAR.html were used.  For optimal
%   results please listen through stereo speakers at 30 and 330 degrees, 0 
%   elevation, and 1.4 meters distance from your head. Also adds a 10 kHz
%   lowpass filter to widen the sweet spot.
%
% Inputs:
%       1)  INFile          : Name of stereophonic .wav file needing xtalk
%       2)  OUTFile         : Name of xtalked .wav file to which the  
%                             signal will be written
%
% Output:
%       A crosstalk cancelled .wav file of the INFile named OUTFile
%

function XTalker( INfile, OUTfile )

% BASIC ERROR CHECKING

if ischar(INfile) == 0,
   error('INfile input needs to be a string');
end

% number of arguments check.

if nargin ~= 2,
    error('number of inputs is incorrect')
end

% READ THE FILES

% The function reads the input .wav file
[y, Fs] = wavread(INfile);
RChannel = y(:,1);
LChannel = y(:,2);  
   
% Function makes sure the sampling rates match up.  (The sampling rates of 
% the files I provided and the KEMAR impulse responses line up at 44100.  
% If user chooses to use different 3D input file, and or different HRTF IRs,
% please make sure they are of the same sampling rate.
if Fs ~= 44100 
    error('HRTF IR and signal sampling rates dont match');
end

% Check length of the signal channels to make sure they are the same    
if length(LChannel) > length(RChannel);
    zeropad = length(LChannel) - length(RChannel);
    RChannel = [RChannel; zeros(zeropad, 1)];
end

if length(RChannel) > length(LChannel);
    zeropad = length(RChannel) - length(LChannel);
    LChannel = [LChannel; zeros(zeropad, 1)];
end

% Reads compact data file of + and - 30 degrees HRTF IRs from KEMAR.
% Right Channel to Left Ear
    fp = fopen('L0e030a.dat','r','ieee-be');
	data = fread(fp, 256, 'short');
	fclose(fp);
	L30 = data(1:256);

% Right Channel to Right Ear    
    fp = fopen('R0e030a.dat','r','ieee-be');
	data = fread(fp, 256, 'short');
	fclose(fp);
	R30 = data(1:256);

% Left Channel to Left Ear
    fp = fopen('L0e330a.dat','r','ieee-be');
	data = fread(fp, 256, 'short');
	fclose(fp);
	L330 = data(1:256);

% Left Channel to Right Ear
    fp = fopen('R0e330a.dat','r','ieee-be');
	data = fread(fp, 256, 'short');
	fclose(fp);
	R330 = data(1:256);
    
% CONVOLVE SIGNALS WITH HRTF IMPULSE RESPONSES TO CREATE THEORETICAL SIGNAL
% OF WHAT YOUR EARS WOULD HEAR IF THE SIGNAL WAS PLAYED TRANSAURALLY    
    L2R = conv(R330, LChannel); % alternate side CROSSTALK SIGNAL
    L2L = conv(L330, LChannel); % same side
    R2R = conv(R30, RChannel); % same side
    R2L = conv(L30, RChannel); % alternate side CROSSTALK SIGNAL
    
% CREATE ANTI PHASE SIGNALS OF CROSSTALK SIGNALS 
    XL2R = L2R * -1;
    XR2L = R2L * -1;
    
% NOTE: ACCORDING TO THE KEMAR WEBSITE THE INTERAURAL TIME DELAY IS STILL 
% PRESENT IN THE TWO EARS, SO THERE IS NO NEED TO ACCOUNT FOR THIS 
% INFORMATION WHEN SENDING THE SIGNAL

% ADD ANTI PHASED CROSSTALK SIGNALS TO ALTERNATE CHANNELS
% find length of INFile channels
    lengthCHANS = length(LChannel);
% find length of Convolved Signals
    lengthCONVS = length(XL2R);
% zeropad channels
    zeropad = lengthCONVS - lengthCHANS;
    LChannel = [LChannel; zeros(zeropad, 1)]; 
    RChannel = [RChannel; zeros(zeropad, 1)];   
% Add signals, divide by to
    XLChannel = (LChannel + XR2L)/2;
    XRChannel = (RChannel + XL2R)/2;
    
% ADD A SIMPLE 10 kHz BUTTERWORTH FILTER TO WIDEN THE SWEET SPOT
    Wn = 10000 / (Fs/2);
    [b,a] = butter(2, Wn, 'low'); 
% filter audio
    FXLChannel = filter(b, a, XLChannel);
    FXRChannel = filter(b, a, XRChannel);

% FUNCTION OUTPUT  
% Allocate left and right channel matrices.
    MTXleft = zeros(length(FXLChannel), 1);
    MTXright = zeros(length(FXRChannel), 1);
    MTXleft = XLChannel;
    MTXright = XRChannel;
    outputMTX = [ MTXright , MTXleft ];
    
% Normalize 
    vectorMAX = 1.001 * (max(abs(outputMTX)));
    outputMTX = outputMTX / max(vectorMAX);

wavwrite ( outputMTX, Fs, OUTfile );

end

