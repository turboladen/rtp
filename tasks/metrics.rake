require 'metric_fu'

MetricFu::Configuration.run do |config|
  config.metrics  = [
                      :churn,
                      :flay,
                      :hotspots,
                      :rcov,
                      :reek,
                      :roodi,
                      :stats,
                    ]
  config.graphs   = [
                      :flay,
                      :rcov,
                      :reek,
                      :roodi,
                      :stats
                    ]
  config.churn    = { 
                      start_date: "1 year ago", 
                      minimum_churn_count: 10 
                    }
  config.flay     = {
                      dirs_to_flay: %w(
                        lib
                        features/step_definitions
                        features/support
                        spec
                      ),
                      minimum_score: 10,
                      filetypes: %w(rb) 
                    } 
  config.reek     = {
                      dirs_to_reek: %w(
                        lib
                        features/step_definitions
                        features/support
                        spec
                      )
                    }
  config.roodi    = { 
                      dirs_to_roodi: %w(
                        lib
                        features/step_definitions
                        features/support
                        spec
                      ),
                      roodi_config: "tasks/roodi_config.yaml" 
                    }
  config.graph_engine = :bluff
end
