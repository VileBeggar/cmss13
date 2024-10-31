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

type Data = {};

export const CellGenerator = (props) => {
  const { act, data } = useBackend<Data>();

  return (
    <Window width={800} height={500} theme="crtblue">
      <Window.Content scrollable className="CellGenerator">
        <Section title="CLONING VAT STATUS">
          <Flex direction="row" justify="space-around">
            <Flex.Item>
              <span className="HeaderSpan">NUTRIENT BEAKER:</span>
              <br />
              <span className="RegularSpan">large beaker</span>
            </Flex.Item>
            <Flex.Item>
              <Button fluid textAlign="center" icon="flask" fontSize="3vw">
                EJECT
              </Button>
            </Flex.Item>
            <Flex.Item>
              <span className="HeaderSpan">CELL SAMPLE:</span>
              <br />
              <span className="RegularSpan">present</span>
            </Flex.Item>
            <Flex.Item>
              <Button
                fluid
                textAlign="center"
                icon="table-cells"
                fontSize="3vw"
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
                >
                  START GROWTH CYCLE
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button fluid icon="door-open" fontSize="2.5vw" color="red">
                  EJECT VAT CONTENTS
                </Button>
              </Flex.Item>
            </Section>
          </Flex.Item>

          <Flex.Item grow={2.5}>
            <Section title="VAT CONDITIONS">
              <Flex justify="space-around">
                <Flex.Item textAlign="Center" className="Gauge">
                  <Icon name="person" size={1.5} />
                  <span className="SubheaderSpan"> MATURITY:</span>
                  <ProgressBar
                    width={14}
                    value={0.46}
                    ranges={{
                      good: [0.66, Infinity],
                      average: [0.33, 0.66],
                      bad: [-Infinity, 0.33],
                    }}
                  >
                    46 / 100
                  </ProgressBar>
                </Flex.Item>
                <Flex.Item textAlign="Center" className="Gauge">
                  <Icon name="temperature-quarter" size={1.5} />
                  <span className="SubheaderSpan"> FLUID LEVEL:</span>
                  <ProgressBar
                    width={14}
                    value={0.26}
                    ranges={{
                      good: [0.5, Infinity],
                      average: [0.25, 0.5],
                      bad: [-Infinity, 0.25],
                    }}
                  >
                    12.4u/50u
                  </ProgressBar>
                </Flex.Item>
              </Flex>
              <Box textAlign="center">
                <Icon name="arrow-up" size={1.5} />
                <span className="SubheaderSpan"> GROWTH SPEED:</span>
                <span className="GrowthGood"> nominal </span>
              </Box>
              <br />
              <Divider />
              <Box textAlign="center">
                <span className="SubheaderSpan">CYCLE STATUS:</span>
                <span className="RegularSpan"> ...growing </span>
              </Box>
            </Section>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};
