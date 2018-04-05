module ReportsHelper

  def cost_analysis_member(size)
    price = ''
    if size < 10995116277760 #10 TB
      price = 0.00
    else
      excess = size - 10995116277760
      price = cost_analysis_subscriber(excess)
    end
    price
  end

  def cost_analysis_subscriber(size)
    cost = size * 0.000000000381988
    price = cost.round(2)
    price
  end

end
