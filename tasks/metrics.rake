require 'metric_fu'

MetricFu::Configuration.run do |config|
  config.metrics  = [
                      :churn,
                      :flog,
                      :flay,
                      :hotspots,
                      :rcov,
                      :reek,
                      :roodi,
                      :stats,
                    ]
  config.graphs   = [
                      :flog,
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
                      ),
                      minimum_score: 10,
                      filetypes: %w(rb) 
                    } 
  config.flog     = { 
                      dirs_to_flog: %w(
                        lib
                        features/step_definitions
                        features/support
                      )
                    }
  config.reek     = { 
                      dirs_to_reek: %w(
                        lib
                        features/step_definitions
                        features/support
                      )
                    }
  config.roodi    = { 
                      dirs_to_roodi: %w(
                        lib
                        features/step_definitions
                        features/support
                      ),
                      roodi_config: "tasks/roodi_config.yaml" 
                    }
  config.rcov[:external] = 'coverage/rcov/rcov.txt'
  config.graph_engine = :bluff
end
