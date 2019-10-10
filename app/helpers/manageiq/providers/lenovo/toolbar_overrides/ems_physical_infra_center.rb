module ManageIQ
  module Providers
    module Lenovo
      module ToolbarOverrides
        class EmsPhysicalInfraCenter < ::ApplicationHelper::Toolbar::Override
          button_group(
            'provider_provision',
            [
              select(
                :provider_provision_choice,
                'pficon pficon-process-automation pficon-lg',
                N_('Provision'),
                :enabled => true,
                :items   => [
                  button(
                    :provision_apply_pattern,
                    'fa fa-clipboard fa-lg',
                    t = N_('Apply Config Pattern'),
                    t,
                    :data  => {
                      'function'      => 'sendDataWithRx',
                      'function-data' => {:controller     => 'provider_dialogs', # this one is required
                                          :button         => :provision_apply_pattern,
                                          :modal_title    => N_('Apply Config Pattern'),
                                          :component_name => 'ApplyConfigPatternFormProvider'}
                    },
                    :klass => ApplicationHelper::Button::ButtonWithoutRbacCheck
                  ),
                  button(
                    :provision_firmware_update,
                    'fa fa-clipboard fa-lg',
                    t = N_('Firmware Update'),
                    t,
                    :data  => {
                      'function'      => 'sendDataWithRx',
                      'function-data' => {:controller     => 'provider_dialogs', # this one is required
                                          :button         => :provision_firmware_update,
                                          :modal_title    => N_('Firmware Update'),
                                          :component_name => 'FirmwareUpdateFormProvider'}
                    },
                    :klass => ApplicationHelper::Button::ButtonWithoutRbacCheck
                  )
                ]
              )
            ]
          )
        end
      end
    end
  end
end
