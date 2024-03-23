# frozen_string_literal: true

module Phlex::Rails::HelperMacros
	# Register a Rails helper that returns safe HTML to be pushed to the output buffer.
	def register_output_helper(method_name)
		class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
			# frozen_string_literal: true

			def #{method_name}(*args, **kwargs, &block)

				output = if block
					helpers.#{method_name}(*args, **kwargs) { capture(&block) }
				else
					helpers.#{method_name}(*args, **kwargs)
				end

				return unless ActiveSupport::SafeBuffer === output

  			context = @_context

				fragments = context.fragments
				if fragments && !context.in_target_fragment
					output = Phlex::Rails::FragmentFinder.extract(output, fragments)
				end

				context.target << output

				nil
			end
		RUBY
	end

	# Register a Rails helper that returns a value that shouldn’t be pushed to the output buffer.
	def register_value_helper(method_name)
		class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
			# frozen_string_literal: true

			def #{method_name}(*args, **kwargs, &block)
				if block
					helpers.#{method_name}(*args, **kwargs) { capture(&block) }
				else
					helpers.#{method_name}(*args, **kwargs)
				end
			end
		RUBY
	end

	# @api private
	def register_builder_yielding_helper(method_name, builder)
		class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
			# frozen_string_literal: true

			def #{method_name}(*args, **kwargs)
				output = if block_given?
					helpers.#{method_name}(*args, **kwargs) { |form|
						capture do
							yield(
								#{builder.name}.new(form,
									view: self
								)
							)
						end
					}
				else
					helpers.#{method_name}(*args, **kwargs)
				end

				return unless ActiveSupport::SafeBuffer === output

  			context = @_context

				fragments = context.fragments
				if fragments && !context.in_target_fragment
					output = Phlex::Rails::FragmentFinder.extract(output, fragments)
				end

				context.target << output

				nil
			end
		RUBY
	end
end
