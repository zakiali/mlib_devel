function fft_wideband_real_init(blk, varargin)
% Initialize and configure an fft_wideband_real block.
%
% fft_real_init(blk, varargin)
%
% blk = the block to configure
% varargin = {'varname', 'value', ...} pairs
%
% Valid varnames:
% FFTSize = Size of the FFT (2^FFTSize points).
% n_inputs = Number of parallel input streams
% input_bit_width = Bit width of input and output data.
% coeff_bit_width = Bit width of coefficient data.
% add_latency = The latency of adders in the system.
% mult_latency = The latency of multipliers in the system.
% bram_latency = The latency of BRAM in the system.
% conv_latency = 
% input_latency = 
% biplex_direct_latency = 
% quantization = Quantization behavior.
% overflow = Overflow behavior.
% arch = 
% opt_target = 
% coeffs_bit_limit = 
% delays_bit_limit = 
% specify_mult = 
% mult_spec = 
% hardcode_shifts = 
% shift_schedule = 
% dsp48_adders = 
% unscramble = 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %
%   Copyright (C) 2007 Terry Filiba, Aaron Parsons                            %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clog('entering fft_wideband_real_init', 'trace');

% Set default vararg values.
defaults = { ...
    'FFTSize', 5, ...
    'n_inputs', 2, ...
    'input_bit_width', 18, ...
    'coeff_bit_width', 18,  ...
    'add_latency', 1, ...
    'mult_latency', 2, ...
    'bram_latency', 2, ...
    'conv_latency', 1, ...
    'input_latency', 0, ...
    'biplex_direct_latency', 0, ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'overflow', 'Saturate', ...
    'arch', 'Virtex5', ...
    'opt_target', 'logic', ...
    'coeffs_bit_limit', 8, ...
    'delays_bit_limit', 8, ...
    'specify_mult', 'off', ...
    'mult_spec', [2 2 2 2 2], ...
    'hardcode_shifts', 'off', ...
    'shift_schedule', [1 1 1 1 1], ...
    'dsp48_adders', 'off', ...
    'unscramble', 'on', ...
};

if same_state(blk, 'defaults', defaults, varargin{:}), return, end
clog('fft_wideband_real_init post same_state', 'trace');
check_mask_type(blk, 'fft_wideband_real');
munge_block(blk, varargin{:});

% Retrieve values from mask fields.
FFTSize = get_var('FFTSize', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
coeff_bit_width = get_var('coeff_bit_width', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
input_latency = get_var('input_latency', 'defaults', defaults, varargin{:});
biplex_direct_latency = get_var('biplex_direct_latency', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});
arch = get_var('arch', 'defaults', defaults, varargin{:});
opt_target = get_var('opt_target', 'defaults', defaults, varargin{:});
coeffs_bit_limit = get_var('coeffs_bit_limit', 'defaults', defaults, varargin{:});
delays_bit_limit = get_var('delays_bit_limit', 'defaults', defaults, varargin{:});
specify_mult = get_var('specify_mult', 'defaults', defaults, varargin{:});
mult_spec = get_var('mult_spec', 'defaults', defaults, varargin{:});
hardcode_shifts = get_var('hardcode_shifts', 'defaults', defaults, varargin{:});
shift_schedule = get_var('shift_schedule', 'defaults', defaults, varargin{:});
dsp48_adders = get_var('dsp48_adders', 'defaults', defaults, varargin{:});
unscramble = get_var('unscramble', 'defaults', defaults, varargin{:});

clog(flatstrcell(varargin), 'fft_wideband_real_init_debug');

% Validate input fields.

if strcmp(specify_mult, 'on') && (length(mult_spec) ~= FFTSize),
    error('fft_wideband_real_init.m: Multiplier use specification for stages does not match FFT size');
    clog('fft_wideband_real_init.m: Multiplier use specification for stages does not match FFT size','error');
    return
end

if n_inputs < 2,
    error('fft_wideband_real_init.m: REAL FFT: Number of inputs must be at least 4!');
    clog('fft_wideband_real_init.m: REAL FFT: Number of inputs must be at least 4!','error');
    return
end

% split up multiplier specification
mults_biplex = 2.*ones(1, FFTSize-n_inputs);
mults_direct = 2.*ones(1, n_inputs);
if strcmp(specify_mult, 'on'),
    mults_biplex(1:FFTSize-n_inputs) = mult_spec(1: FFTSize-n_inputs);
    mults_direct = mult_spec(FFTSize-n_inputs+1:FFTSize);
end

% split up shift schedule
shifts_biplex = ones(1, FFTSize-n_inputs);
shifts_direct = ones(1, n_inputs);
if strcmp(hardcode_shifts, 'on'),
    shifts_biplex(1:FFTSize-n_inputs) = shift_schedule(1: FFTSize-n_inputs);
    shifts_direct = shift_schedule(FFTSize-n_inputs+1:FFTSize);
end

%%%%%%%%%%%%%%%%
% Draw blocks. %
%%%%%%%%%%%%%%%%

% Delete all wires.
delete_lines(blk);

%
% Add input and output ports.
%

reuse_block(blk, 'sync', 'built-in/inport', ...
    'Position', [15 102 45 117], ...
    'Port', '1');
reuse_block(blk, 'shift', 'built-in/inport', ...
    'Position', [15 52 45 67], ...
    'Port', '2');
for i=0:2^n_inputs-1,
    reuse_block(blk, ['in', num2str(i)], 'built-in/inport', ...
        'Position', [15 145+45*i 45 160+45*i], ...
        'Port', num2str(i+3));
end

reuse_block(blk, 'sync_out', 'built-in/outport', ...
    'Position', [805 35 835 50], ...
    'Port', '1');
for i=0:2^(n_inputs-1)-1,
    reuse_block(blk, ['out',num2str(i)], 'built-in/outport', ...
        'Position', [805 80+45*i 835 95+45*i], ...
        'Port', num2str(i+2));
end
of_port_ypos = 125+45*2^(n_inputs-1);
reuse_block(blk, 'of', 'built-in/outport', ...
    'Position', [805 of_port_ypos 835 of_port_ypos+15], ...
    'Port', num2str(2^(n_inputs-1)+2));
%
% Add biplex_real_4x FFT(s).
%

for i=0:2^(n_inputs-2)-1,
    % Add a sync delay.
    reuse_block(blk, ['in_del_sync_4x', num2str(i)], 'casper_library_delays/pipeline', ...
        'Position', [95 108+200*i 145 122+200*i], ...
        'ShowName', 'off', ...
        'latency', tostring(input_latency));

    % Add four input delays.
    reuse_block(blk, ['in_del_4x', num2str(i), '_pol1'], 'casper_library_delays/pipeline', ...
        'Position', [95 158+200*i 145 172+200*i], ...
        'ShowName', 'off', ...
        'latency', tostring(input_latency));
    reuse_block(blk, ['in_del_4x', num2str(i), '_pol2'], 'casper_library_delays/pipeline', ...
        'Position', [95 183+200*i 145 197+200*i], ...
        'ShowName', 'off', ...
        'latency', tostring(input_latency));
    reuse_block(blk, ['in_del_4x', num2str(i), '_pol3'], 'casper_library_delays/pipeline', ...
        'Position', [95 208+200*i 145 222+200*i], ...
        'ShowName', 'off', ...
        'latency', tostring(input_latency));
    reuse_block(blk, ['in_del_4x', num2str(i), '_pol4'], 'casper_library_delays/pipeline', ...
        'Position', [95 233+200*i 145 247+200*i], ...
        'ShowName', 'off', ...
        'latency', tostring(input_latency));

    % Add a biplex block.
    reuse_block(blk, ['fft_biplex_real_4x', num2str(i)], 'casper_library_ffts/fft_biplex_real_4x', ...
        'Position', [170 100+200*i 290 255+200*i], ...
        'LinkStatus', 'inactive', ...
        'FFTSize', num2str(FFTSize-n_inputs), ...
        'input_bit_width', num2str(input_bit_width), ...
        'coeff_bit_width', num2str(coeff_bit_width), ...
        'add_latency', num2str(add_latency), ...
        'mult_latency', num2str(mult_latency), ...
        'bram_latency', num2str(bram_latency), ...
        'conv_latency', num2str(conv_latency), ...
        'quantization', tostring(quantization), ...
        'overflow', tostring(overflow), ...
        'arch', tostring(arch), ...
        'opt_target', tostring(opt_target), ...
        'coeffs_bit_limit', num2str(coeffs_bit_limit), ...
        'delays_bit_limit', num2str(delays_bit_limit), ...
        'specify_mult', tostring(specify_mult), ...
        'mult_spec', mat2str(mults_biplex), ...
        'hardcode_shifts', tostring(hardcode_shifts), ...
        'shift_schedule', tostring(shifts_biplex), ...
        'dsp48_adders', tostring(dsp48_adders));

    % Add four biplex-to-direct delays.
    reuse_block(blk, ['del_4x', num2str(i), '_pol1'], 'casper_library_delays/pipeline', ...
        'Position', [315 133+200*i 365 147+200*i], ...
        'ShowName', 'off', ...
        'latency', tostring(biplex_direct_latency));
    reuse_block(blk, ['del_4x', num2str(i), '_pol2'], 'casper_library_delays/pipeline', ...
        'Position', [315 158+200*i 365 172+200*i], ...
        'ShowName', 'off', ...
        'latency', tostring(biplex_direct_latency));
    reuse_block(blk, ['del_4x', num2str(i), '_pol3'], 'casper_library_delays/pipeline', ...
        'Position', [315 183+200*i 365 197+200*i], ...
        'ShowName', 'off', ...
        'latency', tostring(biplex_direct_latency));
    reuse_block(blk, ['del_4x', num2str(i), '_pol4'], 'casper_library_delays/pipeline', ...
        'Position', [315 208+200*i 365 222+200*i], ...
        'ShowName', 'off', ...
        'latency', tostring(biplex_direct_latency));
end

% Add a sync_out delay for the first biplex block only.
reuse_block(blk, 'del_sync_4x0', 'casper_library_delays/pipeline', ...
    'Position', [315 108 365 122], ...
    'ShowName', 'off', ...
    'latency', tostring(biplex_direct_latency));

%
% Add direct FFT.
%

reuse_block(blk, 'fft_direct', 'casper_library_ffts/fft_direct', ...
    'Position', [465 22 585 22+25*(2^n_inputs+2)], ...
    'LinkStatus', 'inactive', ...
    'FFTSize', num2str(n_inputs), ...
    'input_bit_width', num2str(input_bit_width), ...
    'coeff_bit_width', num2str(coeff_bit_width), ...
    'map_tail', 'on', ...
    'LargerFFTSize', num2str(FFTSize), ...
    'StartStage', num2str(FFTSize-n_inputs+1), ...
    'add_latency', num2str(add_latency), ...
    'mult_latency', num2str(mult_latency), ...
    'bram_latency', num2str(bram_latency), ...
    'conv_latency', num2str(conv_latency), ...
    'quantization', tostring(quantization), ...
    'overflow', tostring(overflow), ...
    'arch', tostring(arch), ...
    'opt_target', tostring(opt_target), ...
    'coeffs_bit_limit', num2str(coeffs_bit_limit), ...
    'specify_mult', tostring(specify_mult), ...
    'mult_spec', mat2str(mults_direct), ...
    'hardcode_shifts', tostring(hardcode_shifts), ...
    'shift_schedule', tostring(shifts_direct), ...
    'dsp48_adders', tostring(dsp48_adders));

%
% Add output unscrambler.
%

if strcmp(unscramble, 'on'),
    reuse_block(blk, 'fft_unscrambler', 'casper_library_ffts/fft_unscrambler', ...
        'Position', [635 20 755 160], ...
        'LinkStatus', 'inactive', ...
        'FFTSize', num2str(FFTSize-1), ...
        'n_inputs', num2str(n_inputs-1), ...
        'bram_latency', num2str(bram_latency));
end

%
% Add remaining blocks.
%

reuse_block(blk, 'slice', 'xbsIndex_r4/Slice', ...
    'Position', [95 52 145 68], ...
    'ShowName', 'off', ...
    'mode', 'Lower Bit Location + Width', ...
    'bit0', num2str(FFTSize-n_inputs), ...
    'nbits', num2str(n_inputs));

of_or_ypos = (of_port_ypos+8) - (16*2^(n_inputs-1))/2;
reuse_block(blk, 'of_or', 'xbsIndex_r4/Logical', ...
    'Position', [670 of_or_ypos 720 of_or_ypos+16*2^(n_inputs-1)-1], ...
    'logical_function', 'OR', ...
    'inputs', tostring(2^(n_inputs-2)+1), ...
    'latency', '1');

%%%%%%%%%%%%%%%
% Draw wires. %
%%%%%%%%%%%%%%%

for i=0:2^(n_inputs-2)-1,
    biplex_name = ['fft_biplex_real_4x', num2str(i)];
    in_del_name = ['in_del_4x', num2str(i)];
    del_name = ['del_4x', num2str(i)];

    add_line(blk, 'sync/1', ['in_del_sync_4x', num2str(i), '/1']);
    add_line(blk, ['in_del_sync_4x', num2str(i), '/1'], [biplex_name, '/1']);
    add_line(blk, 'shift/1', [biplex_name, '/2']);

    add_line(blk, ['in', num2str(4*i+0), '/1'], [in_del_name, '_pol1/1']);
    add_line(blk, ['in', num2str(4*i+1), '/1'], [in_del_name, '_pol2/1']);
    add_line(blk, ['in', num2str(4*i+2), '/1'], [in_del_name, '_pol3/1']);
    add_line(blk, ['in', num2str(4*i+3), '/1'], [in_del_name, '_pol4/1']);

    add_line(blk, [in_del_name, '_pol1/1'], [biplex_name, '/3']);
    add_line(blk, [in_del_name, '_pol2/1'], [biplex_name, '/4']);
    add_line(blk, [in_del_name, '_pol3/1'], [biplex_name, '/5']);
    add_line(blk, [in_del_name, '_pol4/1'], [biplex_name, '/6']);

    add_line(blk, [biplex_name, '/2'], [del_name, '_pol1/1']);
    add_line(blk, [biplex_name, '/3'], [del_name, '_pol2/1']);
    add_line(blk, [biplex_name, '/4'], [del_name, '_pol3/1']);
    add_line(blk, [biplex_name, '/5'], [del_name, '_pol4/1']);
    add_line(blk, [biplex_name, '/6'], ['of_or/', num2str(i+2)]);

    add_line(blk, [del_name, '_pol1/1'], ['fft_direct/', num2str(3+4*i+0)]);
    add_line(blk, [del_name, '_pol2/1'], ['fft_direct/', num2str(3+4*i+1)]);
    add_line(blk, [del_name, '_pol3/1'], ['fft_direct/', num2str(3+4*i+2)]);
    add_line(blk, [del_name, '_pol4/1'], ['fft_direct/', num2str(3+4*i+3)]);
end

add_line(blk, 'shift/1', 'slice/1');
add_line(blk, 'slice/1', 'fft_direct/2');
add_line(blk, 'fft_biplex_real_4x0/1', 'del_sync_4x0/1');
add_line(blk, 'del_sync_4x0/1', 'fft_direct/1');
add_line(blk, ['fft_direct/', num2str(2^n_inputs+3-1)], 'of_or/1');
add_line(blk, 'of_or/1', 'of/1');

if strcmp(unscramble, 'on'),
    add_line(blk, 'fft_direct/1', 'fft_unscrambler/1');
    add_line(blk, 'fft_unscrambler/1', 'sync_out/1');
    for i=1:2^(n_inputs-1),
        add_line(blk, ['fft_direct/', num2str(i+1)], ['fft_unscrambler/', num2str(i+1)]);
        add_line(blk, ['fft_unscrambler/', num2str(i+1)], ['out', num2str(i-1), '/1']);
    end
else
    add_line(blk, 'fft_direct/1', 'sync_out/1');
    for i=1:2^(n_inputs-1),
        add_line(blk, ['fft_direct/', num2str(i+1)], ['out', num2str(i-1), '/1']);
    end
end

% Delete all unconnected blocks.
clean_blocks(blk);

%%%%%%%%%%%%%%%%%%%
% Finish drawing. %
%%%%%%%%%%%%%%%%%%%

fmtstr = sprintf('%d stages\n(%d,%d)\n%s\n%s', FFTSize, input_bit_width, coeff_bit_width, quantization, overflow);
set_param(blk, 'AttributesFormatString', fmtstr);
save_state(blk, 'defaults', defaults, varargin{:});
clog('exiting fft_wideband_real_init','trace');

