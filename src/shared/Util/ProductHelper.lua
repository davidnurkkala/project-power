local ProductHelper = {}

function ProductHelper.getProductKey(product)
	return `product-{product.kind}-{product.id}`
end

return ProductHelper
