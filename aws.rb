require 'aws-sdk-costexplorer'
require 'date'

# month: 今月からNヶ月前から取得する
def get_cost_report(month: 1)
  d = Time.now
  last_month = d.month - month
  last_month = 12 if last_month.zero?
  start_date = "#{d.year}-#{last_month.to_s.rjust(2, "0")}-01"
  end_date   = "#{d.year}-#{d.month.to_s.rjust(2, "0")}-#{d.day.to_s.rjust(2, "0")}"

  client = Aws::CostExplorer::Client.new(region: "us-east-1")
  response = client.get_cost_and_usage({
    time_period: {
      start: start_date,
      end:   end_date, # required
    },
    metrics: ["BLENDED_COST"], # required, accepts BLENDED_COST, UNBLENDED_COST, AMORTIZED_COST, NET_UNBLENDED_COST, NET_AMORTIZED_COST, USAGE_QUANTITY, NORMALIZED_USAGE_AMOUNT
    granularity: "DAILY",      # required, accepts DAILY, MONTHLY, HOURLY
    group_by: [
      {
        type: "DIMENSION",
        key:  "SERVICE",
      },
    ],
  })
end

report = get_cost_report()

my_report = report.results_by_time.each_with_object({}) do |result, r|
  m = result.time_period.start.split("-")[0..1]
  month_key = "#{m[0]}年#{m[1]}月"
  r[month_key] ||= {}
  result.groups.each do |service|
    service_key = service.keys[0]
    r[month_key][service_key] ||= 0
    r[month_key][service_key] += service.metrics["BlendedCost"].amount.to_f
  end
end

# 月次まとめ
my_report.each do |month, repo|
  puts "====[ #{month} ]"
  repo.each do |service, amount|
    puts "#{service.ljust(40, " ")}$ #{amount}"
  end
  puts "#{'合計'.ljust(38, " ")}$ #{repo.values.sum}"
end

# 直近3日分
report.results_by_time[-3..-1].each do |result|
  m = result.time_period.start.split("-")
  puts ""
  puts "#{m[0]}年#{m[1]}月#{m[2]}日"
  result.groups.each do |service|
    service_name = service.keys[0]
    amount       = service.metrics["BlendedCost"].amount.to_f
    puts "#{service_name.ljust(40, " ")}$ #{amount}"
  end
  sum = result.groups.map { |s| s.metrics["BlendedCost"].amount.to_f }.sum
  puts "#{'合計'.ljust(38, " ")}$ #{sum}"
end
