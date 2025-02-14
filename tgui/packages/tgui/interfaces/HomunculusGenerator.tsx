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
  beaker: string;
  beaker_vol_max: number;
  beaker_vol_cur: number;
  growth_rate: number;
  growth_time: string;
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
        <Flex.Item grow={0.9}>
          <Box>Homunculus sample: cell sample</Box>
        </Flex.Item>
        <Flex.Item>
          <Button fluid>EJECT SAMPLE</Button>
        </Flex.Item>
        <FlexLineBreak />
        <Flex.Item grow={0.9}>
          <Box>Nutrient beaker: {data.beaker ? `${data.beaker}` : 'N/A'}</Box>
        </Flex.Item>
        <Flex.Item>
          <Button fluid>EJECT BEAKER</Button>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const StatusPanel = (props) => {
  return (
    <Flex direction="row" wrap="wrap" justify="space-between">
      <Flex.Item>
        <Section title="CONTROL PANEL">
          <Flex.Item>
            <Button>START GENERATIVE CYCLE</Button>
          </Flex.Item>
          <Flex.Item>
            <Button>EJECT OCCUPANT</Button>
          </Flex.Item>
        </Section>
      </Flex.Item>

      <Flex.Item width="50%">
        <Section title="CYCLE INFORMATION">
          <Flex justify="space-around">
            <Flex.Item grow={0.5}>
              <Box textAlign="center">
                <Icon name="temperature-full" /> FLUID LEVEL:
              </Box>
              <ProgressBar value={0.5}>50/50</ProgressBar>
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
          <Flex.Item>
            <Box inline>
              GROWTH RATE: <GrowthRateText /> {data.growth_rate}{' '}
              <Divider hidden /> CYCLE FINISH IN: ({data.growth_time})
            </Box>
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
