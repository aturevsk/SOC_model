classdef Shape_To_ExpandLayer1001 < nnet.layer.Layer & nnet.layer.Formattable
    % A custom layer auto-generated while importing an ONNX network.
    %#codegen

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
        % Specify the properties of the class that will not be modified
        % after the first assignment.
        function p = matlabCodegenNontunableProperties(~)
            p = {
                % Constants, i.e., Vars, NumDims and all learnables and states
                'Vars'
                'NumDims'
                'x_lstm_Constant_outp'
                };
        end
    end


    methods(Static, Hidden)
        % Instantiate a codegenable layer instance from a MATLAB layer instance
        function this_cg = matlabCodegenToRedirected(mlInstance)
            this_cg = soc_model_legacy.coder.Shape_To_ExpandLayer1001(mlInstance);
        end
        function this_ml = matlabCodegenFromRedirected(cgInstance)
            this_ml = soc_model_legacy.Shape_To_ExpandLayer1001(cgInstance.Name);
            if isstruct(cgInstance.Vars)
                names = fieldnames(cgInstance.Vars);
                for i=1:numel(names)
                    fieldname = names{i};
                    this_ml.Vars.(fieldname) = dlarray(cgInstance.Vars.(fieldname));
                end
            else
                this_ml.Vars = [];
            end
            this_ml.NumDims = cgInstance.NumDims;
            this_ml.x_lstm_Constant_outp = cgInstance.x_lstm_Constant_outp;
        end
    end

    methods
        function this = Shape_To_ExpandLayer1001(mlInstance)
            this.Name = mlInstance.Name;
            this.OutputNames = {'x_lstm_Expand_output'};
            if isstruct(mlInstance.Vars)
                names = fieldnames(mlInstance.Vars);
                for i=1:numel(names)
                    fieldname = names{i};
                    this.Vars.(fieldname) = soc_model_legacy.coder.ops.extractIfDlarray(mlInstance.Vars.(fieldname));
                end
            else
                this.Vars = [];
            end

            this.NumDims = mlInstance.NumDims;
            this.x_lstm_Constant_outp = mlInstance.x_lstm_Constant_outp;
        end

        function [x_lstm_Expand_output] = predict(this, x_lstm_Transpose_out__)
            if isdlarray(x_lstm_Transpose_out__)
                x_lstm_Transpose_out_ = stripdims(x_lstm_Transpose_out__);
            else
                x_lstm_Transpose_out_ = x_lstm_Transpose_out__;
            end
            x_lstm_Transpose_outNumDims = 3;
            x_lstm_Transpose_out = soc_model_legacy.coder.ops.permuteInputVar(x_lstm_Transpose_out_, [3 2 1], 3);

            [x_lstm_Expand_output__, x_lstm_Expand_outputNumDims__] = Shape_To_ExpandGraph1002(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, false);
            x_lstm_Expand_output_ = soc_model_legacy.coder.ops.permuteOutputVar(x_lstm_Expand_output__, [3 2 1], 3);

            x_lstm_Expand_output = dlarray(single(x_lstm_Expand_output_), 'CB');
        end

        function [x_lstm_Expand_output, x_lstm_Expand_outputNumDims1003] = Shape_To_ExpandGraph1002(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, Training)

            % Execute the operators:
            % Shape:
            [x_lstm_Shape_output_, x_lstm_Shape_output_NumDims] = soc_model_legacy.coder.ops.onnxShape(x_lstm_Transpose_out, coder.const(x_lstm_Transpose_outNumDims), 0, coder.const(x_lstm_Transpose_outNumDims)+1);

            % Gather:
            [x_lstm_Gather_output, x_lstm_Gather_outputNumDims] = soc_model_legacy.coder.ops.onnxGather(x_lstm_Shape_output_, this.Vars.x_lstm_Constant_2_ou, 0, coder.const(x_lstm_Shape_output_NumDims), this.NumDims.x_lstm_Constant_2_ou);

            % Unsqueeze:
            [shape1002, onnx__Concat_87NumDims] = soc_model_legacy.coder.ops.prepareUnsqueezeArgs(x_lstm_Gather_output, this.Vars.onnx__Unsqueeze_86, coder.const(x_lstm_Gather_outputNumDims));
            onnx__Concat_87 = reshape(x_lstm_Gather_output, shape1002);

            % Concat:
            [x_lstm_Concat_output, x_lstm_Concat_outputNumDims] = soc_model_legacy.coder.ops.onnxConcat(0, {this.Vars.onnx__Concat_230, onnx__Concat_87, this.Vars.x_lstm_Constant_3_ou}, [this.NumDims.onnx__Concat_230, coder.const(onnx__Concat_87NumDims), this.NumDims.x_lstm_Constant_3_ou]);

            % Expand:
            [shape1003, x_lstm_Expand_outputNumDims] = soc_model_legacy.coder.ops.prepareExpandArgs(this.NumDims.x_lstm_Constant_outp, x_lstm_Concat_output);
            x_lstm_Expand_output = this.x_lstm_Constant_outp + zeros(shape1003);

            % Set graph output arguments
            x_lstm_Expand_outputNumDims1003 = coder.const(x_lstm_Expand_outputNumDims);

        end

    end

end