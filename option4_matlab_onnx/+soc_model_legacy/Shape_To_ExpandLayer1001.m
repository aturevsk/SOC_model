classdef Shape_To_ExpandLayer1001 < nnet.layer.Layer & nnet.layer.Formattable
    % A custom layer auto-generated while importing an ONNX network.

    %#ok<*PROPLC>
    %#ok<*NBRAK>
    %#ok<*INUSL>
    %#ok<*VARARG>
    properties (Learnable)
        x_lstm_Constant_outp
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
            name = 'soc_model_legacy.coder.Shape_To_ExpandLayer1001';
        end
    end


    methods
        function this = Shape_To_ExpandLayer1001(name)
            this.Name = name;
            this.OutputNames = {'x_lstm_Expand_output'};
        end

        function [x_lstm_Expand_output] = predict(this, x_lstm_Transpose_out)
            if isdlarray(x_lstm_Transpose_out)
                x_lstm_Transpose_out = stripdims(x_lstm_Transpose_out);
            end
            x_lstm_Transpose_outNumDims = 3;
            x_lstm_Transpose_out = soc_model_legacy.ops.permuteInputVar(x_lstm_Transpose_out, [3 2 1], 3);

            [x_lstm_Expand_output, x_lstm_Expand_outputNumDims] = Shape_To_ExpandGraph1002(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, false);
            x_lstm_Expand_output = soc_model_legacy.ops.permuteOutputVar(x_lstm_Expand_output, [3 2 1], 3);

            x_lstm_Expand_output = dlarray(single(x_lstm_Expand_output), 'CB');
        end

        function [x_lstm_Expand_output] = forward(this, x_lstm_Transpose_out)
            if isdlarray(x_lstm_Transpose_out)
                x_lstm_Transpose_out = stripdims(x_lstm_Transpose_out);
            end
            x_lstm_Transpose_outNumDims = 3;
            x_lstm_Transpose_out = soc_model_legacy.ops.permuteInputVar(x_lstm_Transpose_out, [3 2 1], 3);

            [x_lstm_Expand_output, x_lstm_Expand_outputNumDims] = Shape_To_ExpandGraph1002(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, true);
            x_lstm_Expand_output = soc_model_legacy.ops.permuteOutputVar(x_lstm_Expand_output, [3 2 1], 3);

            x_lstm_Expand_output = dlarray(single(x_lstm_Expand_output), 'CB');
        end

        function [x_lstm_Expand_output, x_lstm_Expand_outputNumDims1003] = Shape_To_ExpandGraph1002(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, Training)

            % Execute the operators:
            % Shape:
            [x_lstm_Shape_output_, x_lstm_Shape_output_NumDims] = soc_model_legacy.ops.onnxShape(x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, 0, x_lstm_Transpose_outNumDims+1);

            % Gather:
            [x_lstm_Gather_output, x_lstm_Gather_outputNumDims] = soc_model_legacy.ops.onnxGather(x_lstm_Shape_output_, this.Vars.x_lstm_Constant_2_ou, 0, x_lstm_Shape_output_NumDims, this.NumDims.x_lstm_Constant_2_ou);

            % Unsqueeze:
            [shape, onnx__Concat_87NumDims] = soc_model_legacy.ops.prepareUnsqueezeArgs(x_lstm_Gather_output, this.Vars.onnx__Unsqueeze_86, x_lstm_Gather_outputNumDims);
            onnx__Concat_87 = reshape(x_lstm_Gather_output, shape);

            % Concat:
            [x_lstm_Concat_output, x_lstm_Concat_outputNumDims] = soc_model_legacy.ops.onnxConcat(0, {this.Vars.onnx__Concat_230, onnx__Concat_87, this.Vars.x_lstm_Constant_3_ou}, [this.NumDims.onnx__Concat_230, onnx__Concat_87NumDims, this.NumDims.x_lstm_Constant_3_ou]);

            % Expand:
            [shape, x_lstm_Expand_outputNumDims] = soc_model_legacy.ops.prepareExpandArgs(this.NumDims.x_lstm_Constant_outp, x_lstm_Concat_output);
            x_lstm_Expand_output = this.x_lstm_Constant_outp + zeros(shape);

            % Set graph output arguments
            x_lstm_Expand_outputNumDims1003 = x_lstm_Expand_outputNumDims;

        end

    end

end