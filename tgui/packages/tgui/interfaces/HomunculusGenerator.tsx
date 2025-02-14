import { useBackend } from '../backend';
import {
  Box,
  Button,
  Divider,
  Flex,
  Icon,
  ProgressBar,
  Section,
  Tooltip,
} from '../components';
import { Window } from '../layouts';

type Data = {
  beaker: string;
  beaker_vol_max: number;
  beaker_vol_cur: number;
  growth_rate: number;
  growth_time: string;
  sample: string;
};
const { act, data } = useBackend<Data>();

export const HomunculusGenerator = (props) => {
  return (
    <Window width={700} height={400} theme="crtblue">
      <Window.Content scrollable>
        <ItemPanel />
        <StatusPanel />
      </Window.Content>
    </Window>
  );
};

const ItemPanel = (props) => {
  return (
    <Section title="INFORMATION">
      <Flex direction="row" wrap="wrap">
        <Flex.Item>
          <Icon name="circle-nodes" />
        </Flex.Item>
        <Divider hidden vertical />
        <Flex.Item grow={0.9}>
          <Box>HOMUNCULUS SAMPLE: {data.sample ? `${data.sample}` : 'N/A'}</Box>
        </Flex.Item>
        <Flex.Item>
          <Button
            fluid
            disabled={data.sample ? false : true}
            onClick={() => act('eject_sample')}
          >
            EJECT SAMPLE
          </Button>
        </Flex.Item>
        <FlexLineBreak />
        <Flex.Item>
          <Icon name="flask" />
        </Flex.Item>
        <Divider hidden vertical />
        <Flex.Item grow={0.9}>
          <Box>NUTRIENT BEAKER: {data.beaker ? `${data.beaker}` : 'N/A'}</Box>
        </Flex.Item>
        <Flex.Item>
          <Button
            fluid
            disabled={data.beaker ? false : true}
            onClick={() => act('eject_beaker')}
          >
            EJECT BEAKER
          </Button>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const StatusPanel = (props) => {
  const fluidLevel = data.beaker_vol_cur / data.beaker_vol_max;
  return (
    <Flex direction="row" justify="space-between">
      <Flex.Item width="50%">
        <Section title="CYCLE INFORMATION">
          <Flex justify="space-around">
            <Flex.Item grow={0.5}>
              <Box textAlign="center">
                <Icon name="temperature-full" /> FLUID LEVEL:
              </Box>
              <ProgressBar
                value={fluidLevel}
                ranges={{
                  good: [0.5, Infinity],
                  average: [0.25, 0.5],
                  bad: [-Infinity, 0.25],
                }}
              >
                {data.beaker ? data.beaker_vol_cur : 0}u /{' '}
                {data.beaker ? data.beaker_vol_max : 0}u
              </ProgressBar>
            </Flex.Item>
            <Divider hidden vertical />
            <Flex.Item grow={0.5}>
              <Box textAlign="center">
                <Icon name="person" /> MATURITY:
              </Box>

              <ProgressBar value={0.5}>50/50</ProgressBar>
            </Flex.Item>
          </Flex>
          <Divider />
          <Flex justify="space-between">
            <Flex.Item>
              <Box>
                GROWTH RATE: <GrowthRateText /> ({data.growth_rate}){' '}
                <Divider hidden /> CYCLE FINISH IN: {data.growth_time}
              </Box>
            </Flex.Item>
            <Tooltip
              position="bottom"
              content="NOTE: The following chemical properties increase growth rate: HEMOGENIC, NUTRITIOUS, HYPERGENETIC."
            >
              <Flex.Item align="center" grow={0.5}>
                <Box>
                  <Icon size={2} name="circle-info" />
                </Box>
              </Flex.Item>
            </Tooltip>
          </Flex>
        </Section>
      </Flex.Item>

      <Flex.Item>
        <Section title="CONTROL PANEL">
          <Flex.Item>
            <Button
              fluid
              disabled={data.sample ? false : true}
              onClick={() => act('toggle_cycle')}
            >
              START GENERATIVE CYCLE
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button fluid>EJECT OCCUPANT</Button>
          </Flex.Item>
        </Section>
      </Flex.Item>
    </Flex>
  );
};

const FlexLineBreak = (props) => {
  return <Flex.Item width="100%" />;
};

const GrowthRateText = (props) => {
  if (data.growth_rate === 0) {
    return 'NONE';
  }

  if (data.growth_rate > 0 && data.growth_rate < 3) {
    return 'SLOW';
  }

  if (data.growth_rate > 3 && data.growth_rate < 5) {
    return 'MODERATE';
  }

  if (data.growth_rate > 5 && data.growth_rate < 8) {
    return 'FAST';
  }

  return 'ABNORMAL';
};
