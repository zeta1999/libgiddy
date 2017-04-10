
#include "kernel_wrappers/common.h"
#ifdef __CUDACC__
#include "kernels/decompression/run_length_encoding.cuh"
#endif

namespace cuda {
namespace kernels {
namespace decompression {
namespace run_length_encoding {

// TODO: This currently ignores the possibility of a sorted variant of the kernel

template<unsigned IndexSize, unsigned UncompressedSize, unsigned RunLengthSize>
class kernel: public cuda::registered::kernel_t {
public:
	REGISTERED_KERNEL_WRAPPER_BOILERPLATE_DEFINITIONS(kernel);

	using uncompressed_type = util::uint_t<UncompressedSize>;
	using run_length_type = util::uint_t<RunLengthSize>;
};

#ifdef __CUDACC__

template<unsigned IndexSize, unsigned UncompressedSize, unsigned RunLengthSize>
launch_configuration_t kernel<IndexSize, UncompressedSize, RunLengthSize>::resolve_launch_configuration(
	device::properties_t            device_properties,
	device_function::attributes_t kernel_function_attributes,
	arguments_type                 extra_arguments,
	launch_configuration_limits_t  limits) const
{
	namespace kernel_ns = cuda::kernels::decompression::run_length_encoding;

	auto uncompressed_length       = any_cast<size_t>(extra_arguments.at("uncompressed_length"));
	auto position_anchoring_period = any_cast<size_t>(extra_arguments.at("position_anchoring_period"));
	kernel_ns::launch_config_resolution_params_t<IndexSize, UncompressedSize, RunLengthSize> params(
		device_properties,
		uncompressed_length, position_anchoring_period);

	return cuda::resolve_launch_configuration(params, limits);
}

template<unsigned IndexSize, unsigned UncompressedSize, unsigned RunLengthSize>
void kernel<IndexSize, UncompressedSize, RunLengthSize>::launch(
	stream::id_t                   stream,
	const launch_configuration_t&  launch_config,
	arguments_type                 arguments) const
{
	using index_type        = util::uint_t<IndexSize>;
	using uncompressed_type = util::uint_t<UncompressedSize>;
	using run_length_type   = util::uint_t<RunLengthSize>;

	auto decompressed               = any_cast<uncompressed_type*       >(arguments.at("decompressed"               ));
	auto run_data                   = any_cast<const uncompressed_type* >(arguments.at("run_data"                   ));
	auto run_lengths                = any_cast<const run_length_type*   >(arguments.at("run_lengths"                ));
	auto position_anchors           = any_cast<const index_type*        >(arguments.at("position_anchors"           ));
	auto intra_run_anchor_offsets   = any_cast<const run_length_type*   >(arguments.at("intra_run_anchor_offsets"   ));
	auto position_anchoring_period  = any_cast<util::uint_t<IndexSize>  >(arguments.at("position_anchoring_period"  ));
	auto num_anchors                = any_cast<util::uint_t<IndexSize>  >(arguments.at("num_anchors"                ));
	auto num_element_runs           = any_cast<util::uint_t<IndexSize>  >(arguments.at("num_element_runs"           ));
	auto uncompressed_length        = any_cast<util::uint_t<IndexSize>  >(arguments.at("uncompressed_length"        ));

	cuda::enqueue_launch(
		cuda::kernels::decompression::run_length_encoding::decompress<IndexSize, UncompressedSize, RunLengthSize>,
		launch_config, stream,
		decompressed, run_data, run_lengths, position_anchors, intra_run_anchor_offsets,
		position_anchoring_period, num_anchors, num_element_runs, uncompressed_length
	);
}

template<unsigned IndexSize, unsigned UncompressedSize, unsigned RunLengthSize>
const device_function_t kernel<IndexSize, UncompressedSize, RunLengthSize>::get_device_function() const
{
	return reinterpret_cast<const void*>(
		cuda::kernels::decompression::run_length_encoding::decompress<IndexSize, UncompressedSize, RunLengthSize>);
}


static_block {
	//       IndexSize   UncompressedSize  RunLengthSize
	//----------------------------------------------------------------------
	kernel < 4,          1,                1 >::registerInSubclassFactory();
	kernel < 4,          2,                1 >::registerInSubclassFactory();
	kernel < 4,          4,                1 >::registerInSubclassFactory();
	kernel < 4,          8,                1 >::registerInSubclassFactory();

	kernel < 4,          1,                2 >::registerInSubclassFactory();
	kernel < 4,          2,                2 >::registerInSubclassFactory();
	kernel < 4,          4,                2 >::registerInSubclassFactory();
	kernel < 4,          8,                2 >::registerInSubclassFactory();

	kernel < 4,          1,                4 >::registerInSubclassFactory();
	kernel < 4,          2,                4 >::registerInSubclassFactory();
	kernel < 4,          4,                4 >::registerInSubclassFactory();
	kernel < 4,          8,                4 >::registerInSubclassFactory();

	kernel < 8,          4,                1 >::registerInSubclassFactory();
	kernel < 8,          4,                2 >::registerInSubclassFactory();
	kernel < 8,          4,                4 >::registerInSubclassFactory();

	kernel < 8,          1,                8 >::registerInSubclassFactory();
	kernel < 8,          4,                8 >::registerInSubclassFactory();
	kernel < 8,          8,                8 >::registerInSubclassFactory();
}
#endif /* __CUDACC__ */

} // namespace run_length_encoding
} // namespace decompression
} // namespace kernels
} // namespace cuda
