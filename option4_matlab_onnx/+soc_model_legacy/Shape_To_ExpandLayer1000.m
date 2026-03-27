classdef Shape_To_ExpandLayer1000 < nnet.layer.Layer & nnet.layer.Formattable
    % A custom layer auto-generated while importing an ONNX network.

    %#ok<*PROPLC>
    %#ok<*NBRAK>
    %#ok<*INUSL>
    %#ok<*VARARG>
    properties (Learnable)
        x_lstm_Constant_1_ou
    end

    properties (State)
    end

    properties
        Vars
        NumDims
    end


    methods(Static, Hidden)
        % Specify the path to the class that will be used for codegen
        function name = matlabCodegenRedirect(~)
            name = 'soc_model_legacy.coder.Shape_To_ExpandLayer1000';
        end
    end


    methods
        function this = Shape_To_ExpandLayer1000(name)
            this.Name = name;
            this.OutputNames = {'x_lstm_Expand_1_outp'};
        end

        function [x_lstm_Expand_1_outp] = predict(this, x_lstm_Transpose_out)
            if isdlarray(x_lstm_Transpose_out)
                x_lstm_Transpose_out = stripdims(x_lstm_Transpose_out);
            end
            x_lstm_Transpose_outNumDims = 3;
            x_lstm_Transpose_out = soc_model_legacy.ops.permuteInputVar(x_lstm_Transpose_out, [3 2 1], 3);

            [x_lstm_Expand_1_outp, x_lstm_Expand_1_outpNumDims] = Shape_To_ExpandGraph1000(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, false);
            x_lstm_Expand_1_outp = soc_model_legacy.ops.permuteOutputVar(x_lstm_Expand_1_outp, [3 2 1], 3);

            x_lstm_Expand_1_outp = dlarray(single(x_lstm_Expand_1_outp), 'CB');
        end

        function [x_lstm_Expand_1_outp] = forward(this, x_lstm_Transpose_out)
            if isdlarray(x_lstm_Transpose_out)
                x_lstm_Transpose_out = stripdims(x_lstm_Transpose_out);
            end
            x_lstm_Transpose_outNumDims = 3;
            x_lstm_Transpose_out = soc_model_legacy.ops.permuteInputVar(x_lstm_Transpose_out, [3 2 1], 3);

            [x_lstm_Expand_1_outp, x_lstm_Expand_1_outpNumDims] = Shape_To_ExpandGraph1000(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, true);
            x_lstm_Expand_1_outp = soc_model_legacy.ops.permuteOutputVar(x_lstm_Expand_1_outp, [3 2 1], 3);

            x_lstm_Expand_1_outp = dlarray(single(x_lstm_Expand_1_outp), 'CB');
        end

        function [x_lstm_Expand_1_outp, x_lstm_Expand_1_outpNumDims1001] = Shape_To_ExpandGraph1000(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, Training)

            % Execute the operators:
            % Shape:
            [x_lstm_Shape_1_outpu, x_lstm_Shape_1_outpuNumDims] = soc_model_legacy.ops.onnxShape(x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, 0, x_lstm_Transpose_outNumDims+1);

            % Gather:
            [x_lstm_Gather_1_outp, x_lstm_Gather_1_outpNumDims] = soc_model_legacy.ops.onnxGather(x_lstm_Shape_1_outpu, this.Vars.x_lstm_Constant_4_ou, 0, x_lstm_Shape_1_outpuNumDims, this.NumDims.x_lstm_Constant_4_ou);

            % Unsqueeze:
            [shape, onnx__Concat_98NumDims] = soc_model_legacy.ops.prepareUnsqueezeArgs(x_lstm_Gather_1_outp, this.Vars.onnx__Unsqueeze_97, x_lstm_Gather_1_outpNumDims);
            onnx__Concat_98 = reshape(x_lstm_Gather_1_outp, shape);

            % Concat:
            [x_lstm_Concat_1_outp, x_lstm_Concat_1_outpNumDims] = soc_model_legacy.ops.onnxConcat(0, {this.Vars.onnx__Concat_231, onnx__Concat_98, this.Vars.x_lstm_Constant_5_ou}, [this.NumDims.onnx__Concat_231, onnx__Concat_98NumDims, this.NumDims.x_lstm_Constant_5_ou]);

            % Expand:
            [shape, x_lstm_Expand_1_outpNumDims] = soc_model_legacy.ops.prepareExpandArgs(this.NumDims.x_lstm_Constant_1_ou, x_lstm_Concat_1_outp);
            x_lstm_Expand_1_outp = this.x_lstm_Constant_1_ou + zeros(shape);

            % Set graph output arguments
            x_lstm_Expand_1_outpNumDims1001 = x_lstm_Expand_1_outpNumDims;

        end

    end

end