% verify_slx.m
cd('/Users/arkadiyturevskiy/Documents/Claude/SOC_model/option5_compressed');
load_system('soc_opt5_compressed');
inPorts  = find_system('soc_opt5_compressed','SearchDepth',1,'BlockType','Inport');
outPorts = find_system('soc_opt5_compressed','SearchDepth',1,'BlockType','Outport');
fprintf('Model loaded OK\n');
fprintf('Inports:  %d\n', numel(inPorts));
fprintf('Outports: %d\n', numel(outPorts));
blks = find_system('soc_opt5_compressed','SearchDepth',2,'Type','Block');
fprintf('Total blocks: %d\n', numel(blks));
for i=1:numel(blks)
    fprintf('  %s  [%s]\n', get_param(blks{i},'Name'), get_param(blks{i},'BlockType'));
end
close_system('soc_opt5_compressed',0);
