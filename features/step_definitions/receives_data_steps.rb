Given /^an RTP::Receiver is runing$/ do
  @receiver = RTP::Receiver.new
end

When /^I call \#running\?$/ do
  @result = @receiver.running?
end

Then /^it returns true$/ do
  pending # express the regexp above with the code you wish you had
end
