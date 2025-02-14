import { useBackend } from '../backend';
import {
  Box,
  Button,
  Divider,
  Flex,
  Icon,
  ProgressBar,
  Section,
} from '../components';
import { Window } from '../layouts';

type Data = {
  status: string;
  growth_rate: number;
  beaker: string;
  fluid_level_max: number;
  fluid_level_cur: number;
  sample: string;
  sample_maturity: number;
  occupant: string;
};

export const CellGenerator = (props) => {
  const { act, data } = useBackend<Data>();
  const fluidLevel = data.fluid_level_cur / data.fluid_level_max;
  const growthRateSpan = function () {
    let textSpan;
    let message;
    switch (data.growth_rate) {
      default:
        textSpan = 'GrowthSlow';
        message = 'NON';
        break;
      case 1:
        textSpan = 'GrowthSlow';
        message = 'NON1';
        break;
      case 2:
        textSpan = 'GrowthNormal';
        message = 'NON2';
        break;
      case 3:
        textSpan = 'GrowthGood';
        message = 'NON3';

        return 'das';
    }
  };

  return (
    <Window width={900} height={650} theme="crtblue">
      <Window.Content scrollable className="CellGenerator">
        <Section title="CLONING VAT STATUS">
          <Flex direction="row" justify="space-around">
            <Flex.Item>
              <Box inline className="HeaderSpan">
                NUTRIENT BEAKER:
              </Box>
              <br />
              <Box inline className="RegularSpan">
                {data.beaker ? `${data.beaker}` : 'N/A'}
              </Box>
            </Flex.Item>
            <Flex.Item>
              <Button
                fluid
                textAlign="center"
                icon="flask"
                fontSize="3vw"
                disabled={data.beaker ? false : true}
                onClick={() => act('eject_beaker')}
              >
                EJECT
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Box inline className="HeaderSpan">
                CELL SAMPLE:
              </Box>
              <br />
              <Box inline className="RegularSpan">
                {data.sample ? 'present' : 'N/A'}
              </Box>
            </Flex.Item>
            <Flex.Item>
              <Button
                fluid
                textAlign="center"
                icon="table-cells"
                fontSize="3vw"
                disabled={data.sample ? false : true}
                onClick={() => act('eject_sample')}
              >
                EJECT
              </Button>
            </Flex.Item>
          </Flex>
        </Section>

        <Flex>
          <Flex.Item>
            <Section title="CONTROLS">
              <Flex.Item>
                <Button
                  fluid
                  icon="hourglass-start"
                  fontSize="2.5vw"
                  color="green"
                  disabled={data.sample ? false : true}
                >
                  START GROWTH CYCLE
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button
                  fluid
                  icon="door-open"
                  fontSize="2.5vw"
                  color="red"
                  disabled={data.occupant ? false : true}
                >
                  EJECT VAT CONTENTS
                </Button>
              </Flex.Item>
            </Section>
          </Flex.Item>

          <Flex.Item grow={2.5}>
            <Section title="VAT CONDITIONS" mx={6}>
              <Flex justify="space-around">
                <Flex.Item textAlign="Center" className="Gauge">
                  <Icon name="person" size={1.5} />
                  <Box inline className="SubheaderSpan">
                    {' '}
                    MATURITY:
                  </Box>
                  <ProgressBar
                    width={14}
                    value={
                      data.sample_maturity ? data.sample_maturity / 100 : 0
                    }
                    ranges={{
                      good: [0.66, Infinity],
                      average: [0.33, 0.66],
                      bad: [-Infinity, 0.33],
                    }}
                  >
                    {data.sample_maturity ? data.sample_maturity / 100 : 0} /
                    100
                  </ProgressBar>
                </Flex.Item>
                <Flex.Item textAlign="Center" className="Gauge">
                  <Icon name="temperature-quarter" size={1.5} />
                  <Box inline className="SubheaderSpan">
                    {' '}
                    FLUIDS:
                  </Box>
                  <ProgressBar
                    width={14}
                    value={fluidLevel}
                    ranges={{
                      good: [0.5, Infinity],
                      average: [0.25, 0.5],
                      bad: [-Infinity, 0.25],
                    }}
                  >
                    {data.beaker ? data.fluid_level_cur : 0}u /{' '}
                    {data.beaker ? data.fluid_level_max : 0}u
                  </ProgressBar>
                </Flex.Item>
              </Flex>
              <Box textAlign="center">
                <Icon name="arrow-up" size={1.5} />
                <Box inline className="SubheaderSpan">
                  {' '}
                  GROWTH SPEED:
                </Box>
                aSbcs
              </Box>
              <br />
              <Divider />
              <Box textAlign="center">
                <Box inline className="SubheaderSpan">
                  CYCLE STATUS:{' '}
                </Box>
                <Box inline className="RegularSpan">
                  {data.status}
                </Box>
              </Box>
            </Section>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};
